// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

`timescale 1ns/1ns

import trdb_pkg::*;

module tb_trace_debugger();

    logic clk;
    logic reset;

    // inputs
    logic inst_valid_i;
    logic iretired_i;
    logic exception_i;
    logic interrupt_i;
    logic [CAUSE_LEN-1:0] cause_i;
    logic [XLEN-1:2] tvec_i;
    logic [XLEN-1:0] tval_i;
    logic [PRIV_LEN-1:0] priv_lvl_i;
    logic [INST_LEN-1:0] inst_data_i;
    logic [XLEN-1:0] pc_i;
    logic [XLEN-1:0] epc_i;

    // outputs
    logic [PTYPE_LEN-1:0]   packet_type_o;
    logic [P_LEN-1:0]       packet_length_o;
    logic [PAYLOAD_LEN-1:0] packet_payload_o;

    // testing only outputs
    logic [PTYPE_LEN-1:0]   expected_packet_type;
    logic [P_LEN-1:0]       expected_packet_length;
    logic [PAYLOAD_LEN-1:0] expected_packet_payload;

    // iteration variable
    logic [31:0] i;

    trace_debugger DUT(
        .clk_i(clk),
        .rst_ni(reset),
        .test_mode_i('0), //TODO: which value to set?
        .inst_valid_i(inst_valid_i),
        .iretired_i(iretired_i),
        .exception_i(exception_i),
        .interrupt_i(interrupt_i),
        .cause_i(cause_i),
        .tvec_i(tvec_i),
        .tval_i(tval_i),
        .priv_lvl_i(priv_lvl_i),
        .inst_data_i(inst_data_i),
        .pc_i(pc_i),
        .epc_i(epc_i),
        .packet_type_o(packet_type_o),
        .packet_length_o(packet_length_o),
        .packet_payload_o(packet_payload_o)
    );

    logic [435:0] test_vector[1000:0];

    initial begin 
        $readmemb("testvectorTopLevel", test_vector);
        i = 0;
        reset = 0; #20; // resetting for two periods
        reset = 1; // set to 1 for the rest of simulation
    end

    always @(posedge clk) begin
        {inst_valid_i,
        iretired_i,
        exception_i,
        interrupt_i,
        cause_i,
        tvec_i,
        tval_i,
        priv_lvl_i,
        inst_data_i,
        pc_i,
        epc_i,
        expected_packet_type,
        expected_packet_length,
        expected_packet_payload
        } = test_vector[i]; #10;
    end

    always @(negedge clk) begin
        // packet_type_o
        if(expected_packet_type !== packet_type_o) begin
            $display("Wrong packet type: %b!=%b", expected_packet_type, packet_type_o);
        end
        // packet_length_o
        if(expected_packet_length !== packet_length_o) begin
            $display("Wrong packet length: %b!=%b", expected_packet_length, packet_length_o);
        end
        // packet_payload_o
        if(expected_packet_payload !== packet_payload_o) begin
            $display("Wrong packet payload: %b!=%b", expected_packet_payload, packet_payload_o);
        end

        // index increase
        i = i + 1;
    end

    always begin
        clk <= 1; #5;
        clk <= 0; #5;
    end

endmodule