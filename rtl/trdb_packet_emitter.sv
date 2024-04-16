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

    // necessary info to assemble packet
    input trdb_format_e packet_format_i,
    input trdb_subformat_e packet_subformat_i,

    // lc (last cycle) signals
    input logic lc_cause_i,
    input logic lc_tval,

    // tc (this cycle) signals
    input logic tc_cause_i,
    input logic tc_tval_i

    // nc (next cycle) signals


    // format 3 subformat 0 specific signals
    input logic is_branch_i,
    input logic is_branch_taken_i,
    input logic [PRIVLEN:0] priv_i,
    input logic [:0] time_i,    // optional
    input logic [:0] context_i, // optional
    input logic [XLEN-1:0] iaddr_i,

    // format 3 subformat 1 specific signals
    //input logic is_branch_i,
    //input logic is_branch_taken_i,
    //input logic [PRIVLEN:0] priv_i,
    //input logic [:0] time_i,
    //input logic [:0] context_i,
    input logic [CAUSELEN:0] ecause_i,
    input logic interrupt_i,
    input logic [XLEN-1:0] trap_handler_address_i,
    //input logic [XLEN-1:0]iaddr_i,
    input logic [TVECLEN:0] tvec_i,
    //input logic [XLEN-1:0] iaddr_i,
    input logic [TVALLEN:0] tval,

    // format 3 subformat 2 specific signals
    //input logic [PRIVLEN:0] priv_i,
    //input logic [:0] time_i,
    //input logic [:0] context_i,

    // format 3 subformat 3 specific signals
    input logic ienable_i, // trace encoder enabled
    input logic encoder_mode_i, // implementation specific, right now only branch trace supported (value==0)
    input logic [1:0] qual_status_i,
    //input logic [:0] ioptions_i, // implementation specific
    // doesn't require an input, it must be created from other inputs
    /*  Run-time configuration bits for INSTRUCTION trace.
        Examples:
            - sequentially inferred jump: don't report the targets of sequentially inferable jumps
            - implicit return: don't report the targets of sequentially inferrable jumps
            - implicit exception: don't report function return addresses
            - branch prediction: branch predictor enabled (not supported in snitch)
            - jump target cache: enabled JTC (not supported in snitch)
            - full address: always output full addresses

        it requires info from the CSRs storing the values
    */
    //input logic seq_inferred_jump_i, // to implement
    input logic trace_implicit_ret_i,
    //input logic trace_implicit_exc_i, // to implement
    //input logic trace_branch_prediction_i, // not supported by snitch, hardwired to 0 (?)
    //input logic jump_target_cache_i, // not supported by snitch, hardwired to 0 (?)
    input logic trace_full_addr_i, // always output full address


    input logic denable_i, // DATA trace enabled
    input logic dloss_i, // one or more DATA trace packets lost
    input logic [:0] doptions_i, // implementation specific
    /* */

    // format 2 specific signals
    //input logic [XLEN-1:0] iaddr_i,
    input logic lc_updiscon_i,
    input logic irreport_i,
    input logic irdepth_i,
    // the last 2 signals are provided by the priority module


    // format 1 specific signals
    /*  this format exists in two modes:
            - address, branch map
            - NO address, branch maps
        
        Their generation depends on the value of branches:
            - 0: no need for address
            - >0: address required
    */
    input logic [:0] branches_i, // in Robert implementation is called branch_cnt
    input logic [:0] branch_map_i,
    //input logic [XLEN-1:0] iaddr_i,
    //input logic lc_updiscon_i,
    //input logic irreport_i,
    //input logic irdepth_i,
    

    // format 0 specific signals
    /*  This format can have two possible subformats:
            - subformat 0: number of correctly predicted branches
            - subformat 1: jump target cache index

    Since snitch does NOT support any of them,
    this format of packet is not necessary

    */
    //input logic [:0] branch_map_i,


    // outputs
    output logic [PTYPELEN:0]packet_type_o, // {packet_format, packet_subformat}
    output logic [PLEN:0] packet_length_o, // in bytes
    output logic [PAYLOADLEN:0] packet_payload_o,

    /*outputs to perform reset resync counter
    and update/reset branch map.
    Question:   it should be done in this module or in
                the one choosing the packet format*/
    output logic branch_map_flush_o, // flushes the branch map
    output logic manual_rst_o,  // not final
                                // understand how the Robert tracer does that

);
    
endmodule