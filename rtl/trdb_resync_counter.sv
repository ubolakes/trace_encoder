/* RESYNC COUNTER */
/* this module keeps track of the emitted packets or cycles elapsed
   it can operate in both ways */

import trdb_pkg::*;

module trdb_counter_emitter
#(  parameter MODE = CYCLE_MODE, // counts cycles as default
    parameter MAX_VALUE = 2'hFFFF ) // default max value, can be personalized
    (
    input logic clk_i,
    input logic rst_ni,

    input logic trace_enabled_i, // it counts with the tracer
    input logic packet_emitted_i,
    input logic resync_rst_i,

    output logic resync_max_o);

    logic [31:0] counter; // placeholder value
    logic enabled;
    logic count_enabled;

    assign count_enabled = trace_enabled_i && enabled;

    always_ff @( posedge clk_i, negedge rst_ni ) begin: counter
        if(~rst_ni) begin
            counter <= '0;
            enabled <= '1; // enabled by default
        end else begin
            if(counter == MAX_VALUE) begin
                resync_max_o <= '1;
                //counter <= '0; // reset to zero is done by priority module
                enabled <= '0; // waits for a resync reset to count
            end else if(PACKET_MODE && count_enabled) begin
                if(packet_emitted_i)
                    counter++;
            end else if(CYCLE_MODE && count_enabled) begin
                counter++;
            end else if(resync_rst_i) begin
                resync_max_o <= '0;
                counter <= '0;
                enabled <= '1;
            end
        end
    end


endmodule