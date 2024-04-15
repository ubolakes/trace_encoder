/*PRIORITY*/
/*
it orders packet generation request by priority
*/

import trdb_pkg::*;

module trdb_priority (
    input logic valid_i,
    
    input logic [XLEN-1:0] full_addr_i,
    input logic [XLEN-1:0] diff_addr_i,
    
    input logic lc_exception_i,
    input logic lc_exception_sync_i,
    
    input logic tc_first_qualified_i,
    input logic nc_unqualified_i,
    //input logic tc_unhalted_i,
    input logic tc_privchange_i,
    //input logic resync
    //input logic branch_map_cnt

    input logic lc_u_discontinuity_i,

    input logic resync_i,
    input logic branch_map_nonempty_i,

    input logic nc_halt_i,
    input logic nc_exception_i,
    input logic nc_privchange_i,
    input logic nc_qualified_i,

    input logic branch_map_full_i,

    input logic tc_context_change_i,

    input logic branch_map _empty_i,

    input logic use_full_addr_i,

    output logic [$clog2(XLEN):0] keep_bits_o,
    output logic                  valid_o,
    output trdb_format_e          packet_format_o,
    output trdb_subformat_e       packet_subformat_o

);
    
endmodule