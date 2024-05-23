// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* BRANCH MAP */
/*
It keeps track of taken and non taken branches.

Whenever a branch happens it updates the branch map
and the number of branches stored.
    
When flush_i signal is asserted, the branch map is
cleaned.
*/

import trdb_pkg::*;

module trdb_branch_map
(
    input logic                         clk_i,
    input logic                         rst_ni,

    input logic                         valid_i, // == nc_is_branch && trace_valid && nc_qualified
    input logic                         branch_taken_i,
    input logic                         flush_i,
    //input logic branch_taken_prediction_i, // non mandatory
    
    output logic [BRANCH_MAP_LEN-1:0]   map_o, // array of branch taken and not 
    output logic [BRANCH_COUNT_LEN-1:0] branches_o, // number of branches stored, up to 31
    //output logic [:0] pbc_o, // non mandatory - branch prediction mode
    //output logic misprediction_o, // non mandatory - ibidem
    output logic                        is_full_o,
    output logic                        is_empty_o
);

    logic [BRANCH_MAP_LEN-1:0]      map_d, map_q;
    logic [BRANCH_COUNT_LEN-1:0]    branch_cnt_d, branch_cnt_q;
    logic                           flush_d, flush_q;

    assign map_o = map_d;
    assign branches_o = branch_cnt_d;
    assign is_full_o = (branch_cnt_d == 31);
    assign is_empty_o = (branch_cnt_d == 0);
    assign flush_d = flush_i;

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) begin
            map_q <= '0;
            branch_cnt_q <= '0;
            flush_q <= '0;
        end else begin
            map_q <= map_d;
            branch_cnt_q <= branch_cnt_d;
            flush_q <= flush_d;
        end
    end

    always_comb begin
        map_d       = map_q;
        branch_cnt_d = branch_cnt_q;
        // flush w/out branch in the same cycle
        if(flush_q) begin
            map_d       = '0;
            branch_cnt_d = '0;
        end
        // flush w/branch in the same cycle
        if(valid_i) begin
            if(flush_q) begin
                map_d[0] = ~branch_taken_i; // adds branch to map
                branch_cnt_d = 5'b1;
            end else begin
                map_d[branch_cnt_q] = ~branch_taken_i;
                branch_cnt_d        = branch_cnt_q + 1;
            end
        end
    end
    
endmodule