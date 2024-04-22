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

    //input logic branch_taken_prediction_i, // non mandatory

    output logic [30:0] map_o, // array of branch taken and not 
    output logic [4:0] branches_o, // number of branches stored, up to 31
    //output logic [:0] pbc_o, // non mandatory
    //output logic misprediction_o, // non mandatory
    output logic is_full_o,
    output logic is_empty_o
);

    /* LOGIC:
        Whenever a branch happens it updates the branch map
        and the number of branches stored.
    
        When flush_i signal is asserted, the branch map is
        cleaned.
    */

    logic [:0]      map_d, map_q;
    logic [4:0]     branch_cnt_d, branch_cnt_q;


    always_comb begin
        map_d       = map_q;
        branchcnt_d = branchcnt_q;

        if(flush_i) begin
            map_d       = '0;
            branchcnt_d = '0;
        end

        if(valid_i) begin
            if(flush_i) begin // branch map flushed
                map_d[0]    = ~branch_taken_i; // why negative?
                branchcnt_d = 5'b1;
            end else begin
                map_d[branchcnt_q] = ~branch_taken_i;
                branchcnt_d        = branchcnt_q + 1;
            end
        end
    end

    assign map_o = map_d;
    assign branches_o = branchcnt_d;
    assign is_full_o = (branchcnt_d == 31);
    assign is_empty_o = (branchcnt_d == 0);

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) begin
            map_q <= '0;
            branchcnt_q <= '0;
        end else begin
            map_q <= map_d;
            branchcnt_q <= branchcnt_d;
        end
    end
    
endmodule