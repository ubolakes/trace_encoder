// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

`timescale 1ns/1ns

import trdb_pkg::*;

module tb_trdb_branch_map();

    logic clk;
    logic reset;

    // inputs
    logic valid_i;
    logic branch_taken_i;
    logic flush_i;

    // outputs
    logic [BRANCH_MAP_LEN-1:0]      map_o;
    logic [BRANCH_COUNT_LEN-1:0]    branches_o;
    logic                           is_full_o;
    logic                           is_empty_o;

    // testing only outputs
    logic [BRANCH_MAP_LEN-1:0]      expected_map;
    logic [BRANCH_COUNT_LEN-1:0]    expected_branches;
    logic                           expected_is_full;
    logic                           expected_is_empty;

    // iteration variable
    logic [31:0] i;

    // DUT instantiation
    trdb_branch_map DUT(
        .clk_i(clk),
        .rst_ni(reset),
        .valid_i(valid_i),
        .branch_taken_i(branch_taken_i),
        .flush_i(flush_i),
        .map_o(map_o),
        .branches_o(branches_o),
        .is_full_o(is_full_o),
        .is_empty_o(is_empty_o)
    );

    logic [40:0] test_vector[1000:0];
    //    length of line   # of lines

    initial begin // reading test vector
        $readmemb("tv_trdb_branch_map", test_vector);
        i = 0;
        reset = 0; #10;
        reset = 1;            
    end

    always @(posedge clk) begin // on posedge we get expected output
        {valid_i,
        branch_taken_i,
        flush_i,
        expected_map,
        expected_branches,
        expected_is_full,
        expected_is_empty
        } = test_vector[i]; #10; 
    end

    always @(negedge clk) begin// on negedge we compare the expected result with the actual one
        // map_o
        if(expected_map !== map_o) begin
            $display("Wrong branch map: %b!=%b", expected_map, map_o); // printed if it's wrong
        end        
        // branches_o
        if(expected_branches !== branches_o) begin
            $display("Wrong branch count: %b!=%b", expected_branches, branches_o);
        end
        // is_full_o
        if(expected_is_full !== is_full_o) begin
            $display("Wrong is_full: %b!=%b", expected_is_full, is_full_o);
        end
        // is_empty_o
        if(expected_is_empty !== is_empty_o) begin
            $display("Wrong is_empty: %b!=%b", expected_is_empty, is_empty_o);
        end
        // index increase
        i = i + 1;
    end

    always begin
        clk <= 1; #5;
        clk <= 0; #5;
    end

endmodule