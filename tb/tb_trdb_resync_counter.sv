// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

`timescale 1ns/1ns

import trdb_pkg::*;

module tb_trdb_resync_counter();

    logic clk;
    logic reset;

    // inputs
    logic trace_enabled_i;
    logic packet_emitted_i;
    logic resync_rst_i;

    // outputs
    logic gt_resync_max_o;
    logic et_resync_max_o;

    // testing only outputs
    logic expected_gt_resync_max;
    logic expected_et_resync_max;

    // iteration variable
    logic [31:0] i;

    // DUT instantiation
    trdb_resync_counter #(
        .MODE(PACKET_MODE), // counting packets
        .MAX_VALUE(7) // counting up to 7
    ) DUT(
        .clk             (clk),
        .reset           (reset),
        .trace_enabled_i (trace_enabled_i),
        .packet_emitted_i(packet_emitted_i),
        .resync_rst_i    (resync_rst_i),
        .gt_resync_max_o (gt_resync_max_o),
        .et_resync_max_o (et_resync_max_o)
    );


    logic [4:0] test_vector[1000:0];
    //    length of line   # of lines

    initial begin // reading test vector
        $readmemb("testbenchVector2", test_vector);
        i = 0;
        reset = 0; #10;
        reset = 1;            
    end

    always @(posedge clk) begin // on posedge we get expected output
        {trace_enabled_i,
        packet_emitted_i,
        resync_rst_i,
        expected_gt_resync_max,
        expected_et_resync_max
        } = test_vector[i]; #10; 
    end

    always @(negedge clk) begin// on negedge we compare the expected result with the actual one
        // gt_resync_max_o
        if(expected_gt_resync_max !== gt_resync_max_o) begin
            $display("Wrong gt_resync_max: %b!=%b", expected_gt_resync_max, gt_resync_max_o); // printed if it's wrong
        end        
        // et_resync_max_o
        if(expected_et_resync_max !== et_resync_max_o) begin
            $display("Wrong branch count: %b!=%b", expected_et_resync_max, et_resync_max_o);
        end
        // index increase
        i = i + 1;
    end

    always begin
        clk <= 1; #5;
        clk <= 0; #5;
    end

endmodule