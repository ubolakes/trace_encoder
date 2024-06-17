// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

`timescale 1ns/1ns

import trdb_pkg::*;

module tb_trdb_itype_detector();

    logic clk;
    logic reset;

    // inputs
    logic valid_i;
    logic [XLEN-1:0]    nc_inst_data_i;
    logic               tc_compressed_i;
    logic [XLEN-1:0]    tc_iaddr_i;
    logic [XLEN-1:0]    nc_iaddr_i;
    logic               nc_exception_i;

    // outputs
    logic nc_branch_o;
    logic tc_branch_taken_o;
    logic nc_updiscon_o;

    // testing only outputs
    logic expected_nc_branch;
    logic expected_tc_branch_taken;
    logic expected_nc_updiscon;

    // iteration variable
    logic [31:0] i;

    // DUT instantiation
    trdb_itype_detector DUT(
        .valid_i          (valid_i),
        .nc_inst_data_i   (nc_inst_data_i),
        .tc_compressed_i  (tc_compressed_i),
        .tc_iaddr_i       (tc_iaddr_i),
        .nc_iaddr_i       (nc_iaddr_i),
        .nc_exception_i   (nc_exception_i),
        .nc_branch_o      (nc_branch_o),
        .tc_branch_taken_o(tc_branch_taken_o),
        .nc_updiscon_o    (nc_updiscon_o)
    );

    logic [101:0] test_vector[1000:0];
    //    length of line   # of lines

    initial begin // reading test vector
        $readmemb("tv_trdb_itype_detector", test_vector);
        i = 0;
        //reset = 0; #10;
        reset = 1;            
    end

    always @(posedge clk) begin // on posedge we get expected output
        {valid_i,
        nc_inst_data_i,
        tc_compressed_i,
        tc_iaddr_i,
        nc_iaddr_i,
        nc_exception_i,
        expected_nc_branch,
        expected_tc_branch_taken,
        expected_nc_updiscon
        } = test_vector[i]; #10; 
    end

    always @(negedge clk) begin// on negedge we compare the expected result with the actual one
        // nc_branch_o
        if(expected_nc_branch !== nc_branch_o) begin
            $display("Wrong nc_branch: %b!=%b", expected_nc_branch, nc_branch_o); // printed if it's wrong
        end        
        // tc_branch_taken_o
        if(expected_tc_branch_taken !== tc_branch_taken_o) begin
            $display("Wrong tc_branch_taken: %b!=%b", expected_tc_branch_taken, tc_branch_taken_o);
        end
        // nc_updiscon_o
        if(expected_nc_updiscon !== nc_updiscon_o) begin
            $display("Wrong nc_updiscon: %b!=%b", expected_nc_updiscon, nc_updiscon_o);
        end

        // index increase
        i = i + 1;
    end

    always begin
        clk <= 1; #5;
        clk <= 0; #5;
    end




endmodule