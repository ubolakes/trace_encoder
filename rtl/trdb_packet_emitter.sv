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
    input logic [XLEN-1:0] iaddr_i,

    // format 3 subformat 1 specific signals
    //input logic is_branch_i,
    //input logic is_branch_taken_i,
    //input logic [PRIVLEN:0] priv_i,
    input logic [:0] time_i,
    input logic [:0] context_i,
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
    input logic [:0] encoder_mode_i, // implementation specific, right now only branch trace supported (value==0)
    input logic [1:0] qual_status_i,
    input logic [:0] ioptions_i, // meaning to be understood
    input logic denable_i, // DATA trace enabled
    input logic dloss_i, // one or more DATA trace packets lost
    input logic [:0] doptions_i, // implementation specific - to be understood

    // format 2 specific signals
    // all must be computed using other info

    // format 1 specific signals
    input logic [:0] branch_map_i,
    //input logic [XLEN-1:0] iaddr_i,

    // format 0 specific signals
    //input logic [:0] branch_map_i,


    // outputs
    output logic [PTYPELEN:0]packet_type_o,
    output logic [PLEN:0] packet_length_o, // in bytes
    output logic [PAYLOADLEN:0] packet_payload_o

    /* TO DO:
    outputs to perform reset resync counter
    and update/reset branch map

    Question:   it should be done in this module or in
                the one choosing the packet format
    */
);
    
endmodule