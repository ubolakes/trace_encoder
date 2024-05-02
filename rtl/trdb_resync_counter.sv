/* RESYNC COUNTER */
/*
It keeps track of the emitted packets or cycles elapsed,
operational mode and threshold are set by the user.

It produces a signal when the counter reaches the specified
threshold and it remains to 1 until it receives a reset signal.
*/

import trdb_pkg::*;

module trdb_resync_counter
#(  parameter MODE = CYCLE_MODE, // counts cycles as default
    parameter MAX_VALUE = 2'hFFFF ) // default max value, can be personalized
    (
    input logic clk_i,
    input logic rst_ni,

    input logic trace_enabled_i, // it comes from filter
    input logic packet_emitted_i,
    input logic resync_rst_i,

    output logic gt_resync_max_o, // greater than the max value, in reality MAX_VALUE
    output logic et_resync_max_o // equals to the max value, in reality MAX_VALUE-1
    );

    localparam COUNTER_LEN = $clog2(MAX_VALUE);

    logic [COUNTER_LEN-1:0] counter; // placeholder value
    logic enabled_d, enabled_q;  // operates the counter
    logic count_enabled;
    logic gt_resync_max_d, gt_resync_max_q;


    assign count_enabled = trace_enabled_i && enabled_q;
    assign enabled_d = counter == MAX_VALUE ? 0 : 1;
    assign gt_resync_max_d = ~enabled_d; //counter == MAX_VALUE ? 1 : 0;
    assign gt_resync_max_o = gt_resync_max_q; 
    assign et_resync_max_o = counter == MAX_VALUE-1 ? 1 : 0;

    always_ff @( posedge clk_i, negedge rst_ni ) begin: counter
        if(~rst_ni) begin
            counter <= '0;
            enabled_q <= '1; // counter enabled by default
            gt_resync_max_q <= '0;
        end else begin
            // the if-then-else block is allowed in this synchronous block?
            if(PACKET_MODE && count_enabled) begin
                if(packet_emitted_i)
                    counter++;
            end else if(CYCLE_MODE && count_enabled) begin
                counter++;
            end else if(resync_rst_i) begin
                counter <= '0; // reset to zero is done after receiving the reset signal
            end
            // updating FF values
            gt_resync_max_q <= gt_resync_max_d;
            enabled_q <= enabled_d;
        end
    end


endmodule