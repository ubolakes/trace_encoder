// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* PACKET EMITTER */
/*
it produces the packets for the output interface
*/

import trdb_pkg::*;

module trdb_packet_emitter
(
    // TODO: add signals width

    input logic                         clk_i,
    input logic                         rst_ni,
    input logic                         valid_i,

    // necessary info to assemble packet
    input trdb_format_e                 packet_format_i,
    input trdb_f_sync_subformat_e       packet_f_sync_subformat_i, // SF for F3
    //input trdb_f_opt_ext_subformat_e    packet_f_opt_ext_subformat_i, // non mandatory, SF for F0

    // lc (last cycle) signals
    input logic [CAUSE_LEN-1:0]         lc_cause_i,
    input logic [XLEN-1:0]              lc_tval_i,
    input logic                         lc_interrupt_i;

    // tc (this cycle) signals
    input logic [CAUSE_LEN-1:0]         tc_cause_i,
    input logic [XLEN-1:0]              tc_tval_i,
    input logic                         tc_interrupt_i;

    // nc (next cycle) signals

    /*  the following signals used to determine 
        if the packet emitter has to put context 
        and/or time in the payload*/
    input logic                         nocontext_i,  // both read from registers
    input logic                         notime_i,
    // in this implementation both hardwired to 0

    // format 3 subformat 0 specific signals
    input logic                         tc_branch_i,
    input logic                         tc_branch_taken_i,
    input logic [PRIV_LEN-1:0]          tc_priv_i,
    //input logic [:0]                    time_i,    // optional
    //input logic [:0]                    context_i, // optional
    input logic [XLEN-1:0]              tc_iaddr_i,

    // format 3 subformat 1 specific signals
    input logic                         lc_tc_mux_i,
    /*  format 3 subformat 1 packets require sometimes lc_cause o tc_cause
        To discriminate I use a mux to choose between lc or tc */

    input logic                         thaddr_i,
    input logic [XLEN-1:0]              tc_tvec_i, // trap handler address
    input logic [XLEN-1:0]              lc_epc_i,
    
    // format 3 subformat 3 specific signals
    input logic                         tc_ienable_i, // trace encoder enabled
    input logic                         encoder_mode_i, // only branch trace supported (value==0)
    input qual_status_e                 qual_status_i,
    input ioptions_e                    ioptions_i,
    // about DATA trace, in stand-by at the moment
    //input logic                         denable_i, // DATA trace enabled, if supported
    //input logic                         dloss_i, // one or more DATA trace packets lost, if supported
    //input logic [:0]                    doptions_i, // it's like ioptions, but for DATA trace


    // format 2 specific signals
    /*  notify -> means the packet was requested by the cpu trigger unit*/ 
    //input logic notify_i, // non mandatory
    
    // most of the time these 2 values can be compressed
    input logic                         lc_updiscon_i,

    // necessary if implicit_return mode is enabled
    //input logic irreport_i,

    //input logic [2**CALL_COUNTER_SIZE-1:0] irdepth_i, // non mandatory, traces nested calls

    // format 1 specific signals
    /*  this format exists in two modes:
            - address, branch map
            - NO address, branch maps
        
        Their generation depends on the value of branches:
            - 0: no need for address
            - >0: address required
    */
    input logic [BRANCH_COUNT_LEN-1:0]  branches_i,
    input logic [BRANCH_MAP_LEN-1:0]    branch_map_i, // can change size to improve efficiency
    
    // format 0 specific signals
    /*  This format can have two possible subformats:
            - subformat 0: number of correctly predicted branches
            - subformat 1: jump target cache index

        Non mandatory, required support by the encoder.
    */
    input logic [$clog2(XLEN):0]        keep_bits_i, // required for address compression

    // outputs
    output logic                        packet_valid_o, // asserted when a packet is generated
    output logic [PAYLOAD_LEN-1:0]      packet_payload_o,
    output logic [P_LEN-1:0]            payload_length_o, // in bytes
    output logic                        branch_map_flush_o, // flushing done after each request
    // to send back to priority module in order to compress them
    output logic [XLEN-1:0]             addr_to_compress_o
);
    
    // internal signals
    logic                               branch;
    logic [XLEN-1:0]                    address;
    logic [CAUSE_LEN-1:0]               ecause;
    logic [XLEN-2:0]                    diff_addr;
    logic [XLEN-1:0]                    latest_addr_d;
    logic [XLEN-1:0]                    latest_addr_q;
    logic                               tval;
    logic                               time_and_context; // if payload requires time/context
    ioptions_e                          ioptions;
    logic                               notify;
    logic                               updiscon;
    logic                               irreport;
    logic [2**CALL_COUNTER_SIZE-1:0]    irdepth;
    logic                               update_latest_address;
    logic [4:0]                         branch_map_off;
    logic [3:0]                         address_off;

    // assigning values
    assign branch = ~(tc_branch_i && tc_branch_taken_i);
    assign address = thaddr_i ? tc_tvec_i : lc_epc_i;
    assign ecause = lc_tc_mux_i ? tc_cause_i : lc_cause_i;
    assign tval = lc_tc_mux_i ? tc_tval_i : lc_tval_i;
    assign interrupt = lc_tc_mux_i ? tc_interrupt_i : lc_interrupt_i;
    assign time_and_context = {notime_i, nocontext_i};
    assign diff_addr = tc_iaddr_i - latest_addr_q;

    always_comb begin : address_to_compress
        addr_to_compress_o = '0;
        if (ioptions_i == FULL_ADDRESS &&
            packet_format_i == F_SYNC &&
            packet_f_sync_subformat_i == SF_TRAP) begin
            addr_to_compress_o = address;
        end else if (packet_format_i == F_SYNC && packet_f_sync_subformat_i == SF_START) begin
            addr_to_compress_o = tc_iaddr_i;
        end else if (ioptions_i !== FULL_ADDRESS &&
                    (packet_format_i == F_ADDR_ONLY ||
                    packet_format_i == F_DIFF_DELTA ||
                    (packet_format_i == F_OPT_EXT &&
                    packet_f_sync_subformat_i == NO_CHANGE))) begin
            addr_to_compress_o = diff_addr;
        end
    end

    // register to store the last address emitted in a packet
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) begin
            latest_addr_q <= '0;
        end else begin
            if(update_latest_address) begin
                latest_addr_q <= tc_iaddr_i;
            end
        end
    end

    // combinatorial network to compute the offset to compress the branch_map
    always_comb begin : branch_map_offset
        if(branches_i == 0) begin
            branch_map_off = 0;
        end else if(branches_i <= 1) begin
            branch_map_off = 1;
        end else if(branches_i <= 9) begin
            branch_map_off = 9;
        end else if(branches_i <= 17) begin
            branch_map_off = 17;
        end else if(branches_i <= 25) begin
            branch_map_off = 25;
        end else begin
            branch_map_off = 31;
        end
    end

    /*  
    the address compression works in byte chunks: based on the value of
    keep_bits_i, the number of least significant bytes to keep is determined.
    
    example:
        keep_bits_i == 7  -> 1 lsB kept
        keep_bits_i == 10 -> 2 lsB kept
        keep_bits_i == 25 -> 4 lsB kept
    */

    // find the number of least significant bytes to keep in the compressed address
    assign address_off = (keep_bits_i + 7)/8;
    
    // combinatorial network to output packets
    always_comb begin
        // init values
        payload_length_o = '0; // in bytes, computed as the length in bit of (type+payload)/8
        packet_payload_o = '0;
        packet_valid_o = '0;
        update_latest_address = '0;
        branch_map_flush_o = '0;
        
        if(valid_i) begin
            // flush the branch map
        /*  the signal is output in this cycle, but the branch map does
            the flush in the next cycle to leave time to the packet
            emitter to read values and put them in the payload 
        */
            branch_map_flush_o = '1;

            // setting the packet to emit as valid
            packet_valid_o = '1;

        /*  packet payload creation: 
            at the beginning it's put in the payload the common part (i.e. the packet format)
            then, for each format and subformat it's put the rest of the payload
        */
            
            // setting the packet format - common for all payloads
            packet_payload_o[1:0] = packet_format_i;

            case(packet_format_i)
            F_SYNC: begin // format 3
                // setting packet subformat - common for all type 3 payloads
                packet_payload_o[3:2] = packet_f_sync_subformat_i;
                
                // setting the rest of payload for each type
                case(packet_f_sync_subformat_i)
                SF_START: begin // subformat 0
                    // updating latest address sent in a packet
                    update_latest_address = '1;

                    case(time_and_context)
                    2'h0: begin
                        packet_payload_o[4+:1+PRIV_LEN] = {
                            branch,
                            tc_priv_i
                        };
                        // address compression
                        case (address_off)
                        1: begin
                            packet_payload_o[5+PRIV_LEN+:8] = {
                                tc_iaddr_i[7:0]
                            };
                        end 
                        2: begin
                            packet_payload_o[5+PRIV_LEN+:16] = {
                                tc_iaddr_i[15:0]
                            };
                        end
                        3: begin
                            packet_payload_o[5+PRIV_LEN+:24] = {
                                tc_iaddr_i[23:0]
                            };
                        end
                        4: begin
                            packet_payload_o[5+PRIV_LEN+:32] = {
                                tc_iaddr_i[31:0]
                            };
                        end
                        5: begin
                            packet_payload_o[5+PRIV_LEN+:40] = {
                                tc_iaddr_i[39:0]
                            };
                        end 
                        6: begin
                            packet_payload_o[5+PRIV_LEN+:48] = {
                                tc_iaddr_i[47:0]
                            };
                        end
                        7: begin
                            packet_payload_o[5+PRIV_LEN+:56] = {
                                tc_iaddr_i[55:0]
                            };
                        end
                        8: begin
                            packet_payload_o[5+PRIV_LEN+:64] = {
                                tc_iaddr_i
                            };
                        end
                        endcase
                        payload_length_o = $ceil($bits(packet_payload_o)/8);
                    end
                    /*TODO: other cases*/
                    endcase
                end
                SF_TRAP: begin // subformat 1
                    // updating latest address sent in a packet
                    update_latest_address = '1;
                    
                    case(time_and_context)
                    2'h0: begin
                        packet_payload_o[4+:1+PRIV_LEN+CAUSE_LEN+2] = {
                            branch,
                            tc_priv_i,
                            ecause,
                            interrupt,
                        };
                        // address compression
                        case (address_off)
                        1: begin
                            packet_payload_o[7+PRIV_LEN+CAUSE_LEN+:8+XLEN] = {
                                address[7:0],
                                tval
                            };
                        end
                        2: begin
                            packet_payload_o[7+PRIV_LEN+CAUSE_LEN+:16+XLEN] = {
                                address[15:0],
                                tval
                            };
                        end
                        3: begin
                            packet_payload_o[7+PRIV_LEN+CAUSE_LEN+:24+XLEN] = {
                                address[23:0],
                                tval
                            };
                        end
                        4: begin
                            packet_payload_o[7+PRIV_LEN+CAUSE_LEN+:32+XLEN] = {
                                address[31:0],
                                tval
                            };
                        end
                        5: begin
                            packet_payload_o[7+PRIV_LEN+CAUSE_LEN+:40+XLEN] = {
                                address[39:0],
                                tval
                            };
                        end
                        6: begin
                            packet_payload_o[7+PRIV_LEN+CAUSE_LEN+:48+XLEN] = {
                                address[47:0],
                                tval
                            };
                        end
                        7: begin
                            packet_payload_o[7+PRIV_LEN+CAUSE_LEN+:56+XLEN] = {
                                address[55:0],
                                tval
                            };
                        end
                        8: begin
                            packet_payload_o[7+PRIV_LEN+CAUSE_LEN+:64+XLEN] = {
                                address,
                                tval
                            };
                        end
                        endcase
                        payload_length_o = $ceil($bits(packet_payload_o)/8);
                    end
                    /*TODO: other cases*/
                    endcase
                end
                SF_CONTEXT: begin // subformat 2
                    case(time_and_context)
                    2'h0: begin
                        packet_payload_o[4+:PRIV_LEN] = {
                            tc_priv_i
                        };
                        payload_length_o = $ceil($bits(packet_payload_o)/8);
                    end
                    /*TODO: other cases*/
                    endcase
                end
                SF_SUPPORT: begin // subformat 3
                    packet_payload_o[4+:1+1+2+3] = {
                        tc_ienable_i,
                        encoder_mode_i,
                        qual_status_i,
                        ioptions_i //,
                        /* info required for data tracing - in the future
                        denable_i,
                        dloss_i,
                        doptions_i*/
                    };
                    payload_length_o = $ceil($bits(packet_payload_o)/8);
                end
                endcase
            end

            F_ADDR_ONLY: begin // format 2
                // updating latest address sent in a packet
                update_latest_address = '1;
                    
                // requires trigger unit in CPU
                /*
                if(notify_i) begin // request from trigger unit
                    notify = !tc_iaddr_i[XLEN-1];
                    updiscon = notify;
                    irreport = updsicon;
                    irdepth = irdepth_i;
                end else begin*/

                // case of an updiscon
                if(lc_updiscon_i) begin
                    notify = tc_iaddr_i[XLEN-1];
                    updiscon = !notify;
                    irreport = updiscon;
                    irdepth = {2**CALL_COUNTER_SIZE{updiscon}};
                /* non mandatory
                end else if(implicit_mode_i && irreport_i) begin // request for implicit return mode
                    notify = tc_iaddr_i[XLEN-1];
                    updiscon = notify;
                    irreport = !updiscon;
                    irdepth = irdepth_i;
                */
                end else begin //other cases
                    notify = tc_iaddr_i[XLEN-1];
                    updiscon = notify;
                    irreport = updiscon;
                    irdepth = {2**CALL_COUNTER_SIZE{updiscon}};
                end
                // address compression
                case (address_off)
                1: begin
                    packet_payload_o[2+:8+3+2**CALL_COUNTER_SIZE] = {
                        tc_iaddr_i[7:0],
                        notify,
                        updiscon,
                        irreport,
                        irdepth
                    };
                end
                2: begin
                    packet_payload_o[2+:16+3+2**CALL_COUNTER_SIZE] = {
                        tc_iaddr_i[15:0],
                        notify,
                        updiscon,
                        irreport,
                        irdepth
                    };
                end
                3: begin
                    packet_payload_o[2+:24+3+2**CALL_COUNTER_SIZE] = {
                        tc_iaddr_i[23:0],
                        notify,
                        updiscon,
                        irreport,
                        irdepth
                    };
                end
                4: begin
                    packet_payload_o[2+:32+3+2**CALL_COUNTER_SIZE] = {
                        tc_iaddr_i[31:0],
                        notify,
                        updiscon,
                        irreport,
                        irdepth
                    };
                end
                5: begin
                    packet_payload_o[2+:40+3+2**CALL_COUNTER_SIZE] = {
                        tc_iaddr_i[39:0],
                        notify,
                        updiscon,
                        irreport,
                        irdepth
                    };
                end
                6: begin
                    packet_payload_o[2+:48+3+2**CALL_COUNTER_SIZE] = {
                        tc_iaddr_i[47:0],
                        notify,
                        updiscon,
                        irreport,
                        irdepth
                    };
                end
                7: begin
                    packet_payload_o[2+:56+3+2**CALL_COUNTER_SIZE] = {
                        tc_iaddr_i[55:0],
                        notify,
                        updiscon,
                        irreport,
                        irdepth
                    };
                end
                8: begin
                    packet_payload_o[2+:64+3+2**CALL_COUNTER_SIZE] = {
                        tc_iaddr_i,
                        notify,
                        updiscon,
                        irreport,
                        irdepth
                    };
                end
                endcase

                payload_length_o = $ceil($bits(packet_payload_o)/8);
                //end
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
                // updating latest address sent in a packet
                update_latest_address = '1;    

                // requires trigger unit in CPU
                /*
                if(notify_i) begin // request from trigger unit
                    notify = !tc_iaddr_i[XLEN-1];
                    updiscon = notify;
                    irreport = updsicon;
                    irdepth = irdepth_i;
                end else begin*/

                // case of an updiscon
                if(lc_updiscon_i) begin
                    notify = tc_iaddr_i[XLEN-1];
                    updiscon = !notify;
                    irreport = updiscon;
                    irdepth = {2**CALL_COUNTER_SIZE{updiscon}};
                /* non mandatory
                end else if(implicit_return_i && irreport_i) begin // request for implicit return mode
                    notify = tc_iaddr_i[XLEN-1];
                    updiscon = notify;
                    irreport = !updiscon;
                    irdepth = irdepth_i;
                */
                end else begin // other cases
                    notify = tc_iaddr_i[XLEN-1];
                    updiscon = notify;
                    irreport = updiscon;
                    irdepth = {2**CALL_COUNTER_SIZE{updiscon}};
                end
                
                // adding branch count and branch map
                if (branch_map_off == 0) begin
                    packet_payload_o[2+:BRANCH_COUNT_LEN] = branches_i;
                end else if (branch_map_off == 1) begin
                    packet_payload_o[2+:BRANCH_COUNT_LEN+1] = {
                        branches_i,
                        branch_map_i[0]
                    };
                end else if (branch_map_off == 9) begin
                    packet_payload_o[2+:BRANCH_COUNT_LEN+9] = {
                        branches_i,
                        branch_map_i[8:0]
                    };
                end else if (branch_map_off == 17) begin
                    packet_payload_o[2+:BRANCH_COUNT_LEN+17] = {
                        branches_i,
                        branch_map_i[16:0]
                    };
                end else if (branch_map_off == 25) begin
                    packet_payload_o[2+:BRANCH_COUNT_LEN+25] = {
                        branches_i,
                        branch_map_i[24:0]
                    };
                end else if (branch_map_off == 31) begin
                    packet_payload_o[2+:BRANCH_COUNT_LEN+31] = {
                        branches_i,
                        branch_map_i[30:0]
                    }
                end

                // attaching the rest of the payload
                if(branches_i < '31) begin // branch map not full - address
                    // address compression
                    case (address_off)
                    1: begin
                        packet_payload_o[2+BRANCH_COUNT_LEN+branch_map_off+:8+3+2**CALL_COUNTER_SIZE] = {
                            diff_addr[7:0],
                            notify,
                            updiscon,
                            irreport,
                            irdepth
                        };
                    end
                    2: begin
                        packet_payload_o[2+BRANCH_COUNT_LEN+branch_map_off+:16+3+2**CALL_COUNTER_SIZE] = {
                            diff_addr[15:0],
                            notify,
                            updiscon,
                            irreport,
                            irdepth
                        };
                    end
                    3: begin
                        packet_payload_o[2+BRANCH_COUNT_LEN+branch_map_off+:24+3+2**CALL_COUNTER_SIZE] = {
                            diff_addr[23:0],
                            notify,
                            updiscon,
                            irreport,
                            irdepth
                        };
                    end
                    4: begin
                        packet_payload_o[2+BRANCH_COUNT_LEN+branch_map_off+:32+3+2**CALL_COUNTER_SIZE] = {
                            diff_addr[31:0],
                            notify,
                            updiscon,
                            irreport,
                            irdepth
                        };
                    end
                    5: begin
                        packet_payload_o[2+BRANCH_COUNT_LEN+branch_map_off+:40+3+2**CALL_COUNTER_SIZE] = {
                            diff_addr[39:0],
                            notify,
                            updiscon,
                            irreport,
                            irdepth
                        };
                    end
                    6: begin
                        packet_payload_o[2+BRANCH_COUNT_LEN+branch_map_off+:48+3+2**CALL_COUNTER_SIZE] = {
                            diff_addr[47:0],
                            notify,
                            updiscon,
                            irreport,
                            irdepth
                        };
                    end
                    7: begin
                        packet_payload_o[2+BRANCH_COUNT_LEN+branch_map_off+:56+3+2**CALL_COUNTER_SIZE] = {
                            diff_addr[55:0],
                            notify,
                            updiscon,
                            irreport,
                            irdepth
                        };
                    end
                    8: begin
                        packet_payload_o[2+BRANCH_COUNT_LEN+branch_map_off+:64+3+2**CALL_COUNTER_SIZE] = {
                            diff_addr,
                            notify,
                            updiscon,
                            irreport,
                            irdepth
                        };
                    end
                    endcase
                end
                payload_length_o = $ceil($bits(packet_payload_o)/8);
            end

            F_OPT_EXT: begin // format 0
                // requires trigger unit in CPU
                /*
                if(notify_i) begin // request from trigger unit
                    notify = !tc_iaddr_i[XLEN-1];
                    updiscon = notify;
                    irreport = updsicon;
                    irdepth = irdepth_i;
                end else begin
                notify = tc_iaddr_i[XLEN-1];
                updiscon = notify;
                irreport = updiscon;
                irdepth = {2**CALL_COUNTER_SIZE{updiscon}};
                end */
                
                /* requires non mandatory support for jtc and branch prediction
                case(packet_f_opt_ext_subformat_i)
                SF_PBC: begin // subformat 0
                /*  There can be two type of payloads for this subformat:
                    1. no address, branch count
                    2. address, branch count
                * /    
                
                    // only for F0SF0 payload w/address
                    // updating latest address sent in a packet
                    //update_latest_address = '1;

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