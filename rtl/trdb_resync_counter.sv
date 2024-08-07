// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* RESYNC COUNTER */
/*
It keeps track of the emitted packets or cycles elapsed,
operational mode and threshold are set by the user.

It produces a signal when the counter reaches the specified
threshold and it remains to 1 until it receives a reset signal.
*/

import trdb_pkg::*;

module trdb_resync_counter #(
    parameter MODE = CYCLE_MODE, // counts cycles as default
    parameter MAX_VALUE = 16'hFFFF // default max value, can be personalized
    )
    (
    input logic clk_i,
    input logic rst_ni,

    input logic trace_enabled_i, // it comes from filter
    input logic packet_emitted_i,
    input logic resync_rst_i,

    output logic gt_resync_max_o, // greater than the max value, in reality MAX_VALUE
    output logic et_resync_max_o // equals to the max value, in reality MAX_VALUE-1
    );

    logic [$clog2(MAX_VALUE):0] counter_q, counter_d;
    logic                       enabled_d, enabled_q;  // operates the counter
    logic                       count_enabled;
    logic                       gt_resync_max_d, gt_resync_max_q;
    logic                       packet_count_enabled;
    logic                       cycle_count_enabled;

    assign count_enabled = trace_enabled_i && enabled_q;
    assign enabled_d = (counter_q <= MAX_VALUE);
    assign gt_resync_max_d = ~enabled_d; //counter == MAX_VALUE ? 1 : 0;
    assign gt_resync_max_o = (counter_d > MAX_VALUE-1); //? 1 : 0; // gt_resync_max_q; 
    assign et_resync_max_o = (counter_d == MAX_VALUE-1);// ? 1 : 0;
    assign packet_count_enabled = count_enabled && PACKET_MODE && packet_emitted_i;
    assign cycle_count_enabled = count_enabled && CYCLE_MODE;

    always_ff @( posedge clk_i, negedge rst_ni ) begin: counter
        if(~rst_ni) begin
            counter_q <= '0;
            counter_d <= '0;
            enabled_q <= '1; // counter enabled by default
            gt_resync_max_q <= '0;
        end else begin
            // updating FF values
            enabled_q <= enabled_d;
            // updating counters values
            if(packet_count_enabled || cycle_count_enabled) begin
                counter_d += 1;
                counter_q <= counter_d;
            end else if(resync_rst_i) begin
                counter_d <= '0;
                counter_q <= '0; // reset to zero is done after receiving the reset signal
            end
        end
    end


endmodule