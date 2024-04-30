/*REG*/
/*
it stores values for the encoder in memory mapped registers
*/

import trdb_pkg::*;

module trdb_reg
    #()
    (
    input logic clk_i,
    input logic rst_ni,

    // registers are divided according to the module
    // common ones are under the first label

    // common settings and control
    output logic trace_activated_o,
    // priority settings and control

    // resync_counter settings and control

    // packet_emitter settings and control
    output logic nocontext_o,
    output logic notime_o,
    output logic encoder_mode_o,
    output logic delta_address_o,
    output logic full_address_o,
    output logic implicit_exception_o,
    output logic sijump_o,
    output logic implicit_return_o,
    output logic branch_prediction_o,
    output logic jump_target_cache_o,



    );

endmodule