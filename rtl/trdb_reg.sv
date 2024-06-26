// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/*REG*/
/*
it stores values for the encoder in memory mapped registers
*/

import trdb_pkg::*;

module trdb_reg
    (
    input logic clk_i,
    input logic rst_ni,

    // tracing management
    input logic trace_req_off_i, // from filter
    input logic trace_req_on_i, // directly from trigger unit

    output logic trace_enable_o,    // turned off by filter
    output logic trace_activated_o, // managed by user
    // packet_emitter settings and control
    output logic nocontext_o,
    output logic notime_o,
    output logic encoder_mode_o, // hardwired to 0 - can only be 0 according to spec
    output logic delta_address_o,
    /* non mandatory signals - hardwired to 0
    output logic full_address_o,
    output logic implicit_exception_o,
    output logic sijump_o,
    output logic implicit_return_o,
    output logic branch_prediction_o,
    output logic jump_target_cache_o,*/
    output ioptions_e configuration_o,
    output logic clk_gated_o
);
    // hardwired to 0 signals - not yet implemented
    logic full_address;
    logic implicit_exception;
    logic sijump;
    logic implicit_return;
    logic branch_prediction;
    logic jump_target_cache;
    // FFs I/Os
    logic trace_enable_d, trace_enable_q;

    logic clk_gated;
    logic test_enabled;

    // assignments
    assign delta_address_o = '1;
    assign full_address = '0;
    assign implicit_exception = '0;
    assign sijump = '0;
    assign implicit_return = '0;
    assign branch_prediction = '0;
    assign jump_target_cache = '0;
    assign configuration_o = DELTA_ADDRESS; // so far only this supported
    
    assign trace_enable_d = ~trace_req_off_i || trace_req_on_i;
    assign trace_enable_o = '1; // set to 1 for testing purpose //trace_enable_q;

    assign nocontext_o = '1;
    assign notime_o = '1;
    assign encoder_mode_o = '0;
    assign trace_activated_o = '1;

    assign clk_gated_o = clk_gated;
    assign test_enabled = '0;

    // clock gating module
    pulp_clock_gating i_pulp_clock_gating(
        .clk_i    (clk_i),
        .en_i     (trace_activated_o),
        .test_en_i(test_enabled),
        .clk_o    (clk_gated)
    );

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if(~rst_ni) begin
            trace_enable_q <= '0;
        end else begin
            trace_enable_q <= trace_enable_d;
        end
    end
endmodule