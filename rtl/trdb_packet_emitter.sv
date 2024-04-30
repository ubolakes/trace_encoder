/* PACKET EMITTER */
/*
it produces the packets for the output interface
*/

import trdb_pkg::*;

module trdb_packet_emitter
(
    // TO DO: add signals width

    input logic clk_i,
    input logic rst_ni,

    input logic valid_i,

    // necessary info to assemble packet
    input trdb_format_e packet_format_i,
    input trdb_f_sync_subformat_e packet_f_sync_subformat_i, // subformat for format 3
    //input trdb_f_opt_ext_subformat_e packet_f_opt_ext_subformat_i, // non mandatory,subformat for format 0

    // lc (last cycle) signals
    input logic lc_cause_i,
    input logic lc_tval_i,

    // tc (this cycle) signals
    input logic tc_cause_i,
    input logic tc_tval_i,

    // nc (next cycle) signals

    /*  the following signals used to determine 
        if the packet emitter has to put context 
        and/or time in the payload*/
    input logic nocontext_i,  // both read from registers
    input logic notime_i,
    // in this implementation both hardwired to 0

    // format 3 subformat 0 specific signals
    input logic is_branch_i,
    input logic is_branch_taken_i,
    input logic [PRIV_LEN:0] priv_i,
    //input logic [:0] time_i,    // optional
    //input logic [:0] context_i, // optional
    input logic [XLEN-1:0] iaddr_i,
    input logic resync_timeout_i, // requested resync by the timer

    // format 3 subformat 1 specific signals
    input logic cause_mux_i,
    /*  format 3 subformat 1 packets require sometimes lc_cause o tc_cause
        how do I discriminate them? Need another signal?
        The use of lc or tc values depends on a previous updiscon:
        combinatorial network that determines the ecause depending on
        the case.
        Idea:   output a signal that operates a mux to choose between lc or tc*/

    input logic tval_mux_i, 
    // same as cause_mux, but for lc_tval o tc_tval

    input logic interrupt_i,
    input logic thaddr_i,
    input logic [XLEN-1:0] tvec_i, // trap handler address
    input logic [XLEN-1:0] epc_i,
    
    // format 3 subformat 3 specific signals
    input logic ienable_i, // trace encoder enabled
    input logic encoder_mode_i, // implementation specific, right now only branch trace supported (value==0). Hardwire to 0?
    input logic [1:0] qual_status_i, // to be understood
    /*  it indicates the tracing has ended, it has two possible values: ended_rep and ended_ntr
        At page 37 of the specs there's a more accurate description*/
    // it doesn't require a dedicated input signal
    // because it's generated using other signals

    /*  used for ioptions value
        determine if a certain mode is enabled  */
    input logic delta_address_i, // mandatory
    input logic full_address_i, // non mandatory
    input logic implicit_exception_i, // non mandatory
    input logic sijump_i, // non mandatory
    input logic implicit_return_i, // non mandatory
    input logic branch_prediction_i, // non mandatory
    input logic jump_target_cache_i, // non mandatory
    
    // about DATA trace, in stand-by at the moment
    //input logic denable_i, // DATA trace enabled, if supported
    //input logic dloss_i, // one or more DATA trace packets lost, if supported
    //input logic [:0] doptions_i, // it's like ioptions, but for DATA trace


    // format 2 specific signals
    /*  notify -> means the packet was requested by the cpu trigger unit*/ 
    //input logic notify_i, // non mandatory
    
    /* updiscon ->  if it has a different value from notify,
                    means there was an exception/other flow 
                    changes during a loop.
                    This way the trace reconstruction is easier.
                    For a better description refer to page 38 of the spec
    */
    // most of the time these 2 values can be compressed
    input logic lc_updiscon_i,

    input logic irreport_i,
    /*  the value of irreport is different from updiscon
        if this packet is reporting an instr that is the
        last one retired before an exception, interrupt, 
        priv change, resync.
        With this is also reported the traced nested calls, 
        that are counted if implicit_return mode is enabled
        (and available)
    */
    //input logic [:0] irdepth_i, // keeps count of the traced nested calls

    // format 1 specific signals
    /*  this format exists in two modes:
            - address, branch map
            - NO address, branch maps
        
        Their generation depends on the value of branches:
            - 0: no need for address
            - >0: address required
    */
    input logic [4:0] branches_i, // in Robert implementation is called branch_cnt
    input logic [31:0] branch_map_i, // in the packet it can change size to improve efficiency
    
    // format 0 specific signals
    /*  This format can have two possible subformats:
            - subformat 0: number of correctly predicted branches
            - subformat 1: jump target cache index

        Non mandatory, required support by the encoder.
    */

    // outputs
    output logic [P_LEN:0] payload_length_o, // in bytes
    /* this module produces only the packet payload
    that is the forwarded to the encapsulator that
    takes care of the type and length.*/
    output logic [PAYLOAD_LEN:0] packet_payload_o,
    output logic packet_valid_o, // asserted when a packet is generated

    output logic branch_map_flush_o, // branch map flushed after each request
);
    
    // internal signals
    logic branch;
    logic [XLEN-1:0] address;
    logic [CAUSE_LEN:0] ecause;
    logic [:0] diff_address;
    logic branch_map_flush_d, branch_map_flush_q;
    logic tval;
    logic time_and_context; // determines if the payload requires time and/or context
    logic ioptions ioptions;

    // assigning values
    assign branch = ~(is_branch_i && is_branch_taken_i);
    assign address = thaddr_i ? tvec_i : epc_i;
    assign ecause = cause_mux_i ? tc_cause_i : lc_cause_i;
    assign tval = tval_mux_i ? tc_tval_i : lc_tval_i;
    assign time_and_context = {notime_i, nocontext_i};

    // combinatorial network to output packets
    always_comb begin : set_packet_bits
        // init values
        payload_length_o = '0; // in bytes, computed as the length in bit of (type+payload)/8
        packet_payload_o = '0;
        packet_valid_o = '0;
        
        if(valid_i) begin
            // flush the branch map
        /*  branch map flushing is done in the next cycle.
            Because we don't want it to be instantly deleted
            since we need to read from it to populate the 
            packet payload.    
        */
            branch_map_flush_d = '1;


            case(packet_format_i)

            F_SYNC: begin // format 3
                case(packet_f_sync_subformat_i)

                SF_START: begin // subformat 0
                    case(time_and_context)
                    2'h0: begin
                        packet_payload_o = {F_SYNC, F_START, branch, priv_i, iaddr_i};
                        payload_length_o = $bits(packet_payload_o)/8; //(2 + 2 + 1 + PRIV_LEN + XLEN-1)/8;
                    end
                    /*TODO: other cases*/
                    endcase
                    packet_valid_o = '1;
                end

                SF_TRAP: begin // subformat 1
                    case(time_and_context)
                    2'h0: begin
                        packet_payload_o = {F_SYNC, SF_TRAP, branch, priv_i, ecause, interrupt_i, thaddr_i, address, tval};
                        payload_length_o = $bits(packet_payload_o)/8; //(2 + 2 + 1 + PRIV_LEN + CAUSE_LEN + 1 + 1 + XLEN-1 + TVAL_LEN)/8;
                    end
                    /*TODO: other cases*/
                    endcase
                    packet_valid_o = '1;
                end
                
                SF_CONTEXT: begin // subformat 2
                    case(time_and_context)
                    2'h0: begin
                        packet_payload_o = {F_SYNC, SF_CONTEXT, priv_i};
                        payload_length_o = $bits(packet_payload_o)/8; //(2 + 2 + PRIV_LEN)/8;
                    end
                    /*TODO: other cases*/
                    endcase
                    packet_valid_o = '1;
                end
                
                SF_SUPPORT: begin // subformat 3
                    // computing ioptions mode
                    if(delta_address_i) begin
                        ioptions = DELTA_ADDRESS;
                    end else if(full_address_i) begin
                        ioptions = FULL_ADDRESS;
                    end else if(implicit_exception_i) begin
                        ioptions = IMPLICIT_EXCEPTION;
                    end else if(sijump_i) begin
                        ioptions = SIJUMP;
                    end else if(implicit_return_i) begin
                        ioptions = IMPLICIT_RETURN;
                    end else if(branch_prediction_i) begin
                        ioptions = BRANCH_PREDICTION;
                    end else if(jump_target_cache_i) begin
                        ioptions = JUMP_TARGET_CACHE;
                    end

                    packet_payload_o = {F_SYNC, SF_SUPPORT, ienable_i, encoder_mode_i, qual_status_i, ioptions/*, denable_i, dloss_i, doptions_i*/};
                    payload_length_o = $bits(packet_payload_o)/8; //(2 + 2 + 1 + 1 + 2 + $bits(ioptions) /*+ 1 + 1 + doptions length*/)/8;
                    packet_valid_o = '1;
                end
                endcase
            end


            F_ADDR_ONLY: begin // format 2
                packet_payload_o = {F_ADDR_ONLY, iaddr_i, notify_i, lc_updiscon_i, irreport_i, irdepth_i};
                payload_length_o = $bits(packet_payload_o)/8; //(2 + XLEN-1 + 1 + 1 + 1 + $bits(irdepth_i))/8;
                packet_valid_o = '1;
            end


            F_DIFF_DELTA: begin // format 1
            /*  There can be two type of payloads for this format:
                1. address, branch map
                2. no address, branch map
                
                Type 1 payload is used when there has been at least
                one branch from last packet. This can be determined
                by the number of branches in the branch map.

                Type 2 payload is used when the address is not needed,
                for examples if the branch map is full.
            */
                if(branches_i < '31) begin // branch map not full - address
                    packet_payload_o = {F_DIFF_DELTA, branches_i, branch_map_i, iaddr_i, notify_i, lc_updiscon_i, irreport_i, irdepth_i};
                    payload_length_o = $bits(packet_payload_o)/8; //(2 + 5 + 31 + XLEN-1 + 1 + 1 + 1 + $bits(irdepth_i))/8;
                end else /*if(branches_i == '31)*/ begin // branch map full - no address
                    packet_payload_o = {F_DIFF_DELTA, branches_i, branch_map_i};
                    payload_length_o = $bits(packet_payload_o)/8; //(2 + 5 + 31)/8;
                end
                packet_valid_o = '1;
            end


            F_OPT_EXT: begin // format 0
                /* requires non mandatory support for jtc and branch prediction
                case(packet_f_opt_ext_subformat_i)
                SF_PBC: begin // subformat 0
                /*  There can be two type of payloads for this subformat:
                    1. no address, branch count
                    2. address, branch count
                * /    
                    packet_payload_o = {F_OPT_EXT, SF_PBC, etc..};
                    payload_length_o = $bits(packet_payload_o)/8;;
                    packet_valid_o = '1;
                end

                SF_JTC: begin // subformat 1
                    packet_payload_o = {F_OPT_EXT, SF_JTC, etc..};
                    payload_length_o = $bits(packet_payload_o)/8;;
                    packet_valid_o = '1;
                end
                endcase
                */
            end
            endcase
        
        end
    end


endmodule