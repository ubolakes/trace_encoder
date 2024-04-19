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

    /* value of the branch taken prediction
        0: not taken
        1: taken */
    input logic branch_taken_prediction_i, // not supported by snitch

    output logic [:0] map_o, // array of branch taken and not 
    output logic [:0] branches_o, // number of branches stored
    output logic [:0] pbc_o, // correctly predicted branch count, not supported by snitch
    output logic misprediction_o, // tells if the prediction was right, not supported by snitch
    output logic is_full_o,
    output logic is_empty_o
);
    
endmodule