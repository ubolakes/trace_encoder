/* FILTER MODULE */
/*
it enables and disables the trace encoder
*/

import trdb_pkg::*;

module trdb_filter
(
    // setting input values are taken from registers
    
    // uncommented signals are the ones required to simply turn on and of the encoder

    // enable/disable tracing
    input logic trace_activated_i,
    output logic trace_req_deactivate_o, // writes to register

    /*
    // consider/ignore filters
    input logic apply_filters_i,

    // tracing a specific privilege mode
    input logic trace_selected_priv_i, // on/off
    input logic [1:0] which_priv_i, // selected priv
    input logic [1:0] priv_lvl_i, // input priv

    // trace specific address range
    input logic trace_range_event_i,
    input logic trace_stop_event_i,
    input logic [XLEN-1:0] trace_lower_addr_i,
    input logic [XLEN-1:0] trace_higher_addr_i
    input logic [XLEN-1:0] iaddr_i
    
    // signals to determine matches
    output logic trace_range_match_o,
    output logic trace_priv_match_o,
    */
    output logic trace_qualified_o
);



endmodule