/* BRANCH MAP */
/*
it keeps track of taken and non taken branches
*/

module trdb_branch_map
(
    input logic clk_i,
    input logic rst_ni,

    input logic valid_i,
    input logic branch_taken_i,
    input logic flush_i,

    output logic [:0] map_o, // to be understood
    output logic [:0] branches_o, // to be understood
    output logic is_full_o,
    output logic is_empty_o
);
    
endmodule