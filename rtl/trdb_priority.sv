/*PRIORITY*/
/*
change this module name to a more appropriate one
for example "packet identifier" or something similar
*/
/*
it orders packet generation request by priority
*/

import trdb_pkg::*;

module trdb_priority (
    input logic valid_i,

    // refer to page 53 of the specs for clarification

    /*TO DO: determine width of signals, not all are logic*/

    // lc (last cycle) signals
    input logic lc_exception_i,
    input logic lc_updiscon_i, // updsicon == uninferable PC discontinuity

    // tc (this cycle) signals
    input logic tc_qualified_i,
    input logic tc_is_branch_i,
    input logic tc_exception_i,
    input logic tc_reported_i, // what's the meaning? refer to page 51 of spec
    input logic tc_first_qualified_i,
    input logic tc_privchange_i,
    input logic tc_context_change_i, // determinable using a comparator with lc_context and tc_context
    input logic tc_context_change_w_discontinuity_i, // understand the meaning
    input logic tc_exception_sync_i, // resync timer expired
    input logic tc_branch_map_empty_i,
    input logic tc_er_n_i, // simultaneous exception and retirement, maybe split in more signals?
    input logic tc_branch_map_full_i,
    input logic tc_imprecise_context_change_i, // understand
    // understand the meaning of branches and pbc in graph at page 53

    // nc (next cycle) signals
    input logic nc_exception_i,
    input logic nc_privchange_i,
    input logic nc_precise_context_change_i,
    input logic nc_context_change_w_discontinuity_i,
    input logic nc_branch_map_empty_i,
    input logic nc_qualified_i,

    // to do: outputs
    output logic            valid_o,
    output trdb_format_e    packet_format_o,
    output trdb_subformat_e packet_subformat_o);



    // combinatorial network to determine packet format
    always_comb begin : select_packet_format
        // init values
        valid_o = '0;
        packet_format_o = '0;
        packet_subformat_o = '0;
    
        if(valid_i) begin
            /* format 3 packet */
            // subformat 0


            // subformat 1


            // subformat 2


            // subformat 3




            // format 2 packet






            // format 1 packet





            // format 0 packet
    



        end
    end


endmodule