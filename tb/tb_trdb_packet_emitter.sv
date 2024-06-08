// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

`timescale 1ns/1ns

import trdb_pkg::*;

module tb_trdb_packet_emitter();

    logic clk;
    logic reset;

    // inputs
    logic                           valid_i;
    trdb_format_e                   packet_format_i;
    trdb_f_sync_subformat_e         packet_subformat_i;
    logic [CAUSE_LEN-1:0]           lc_cause_i;
    logic [XLEN-1:0]                lc_tval_i;
    logic                           lc_interrupt_i;
    logic [CAUSE_LEN-1:0]           tc_cause_i;
    logic [XLEN-1:0]                tc_tval_i;
    logic                           tc_interrupt_i;
    logic                           nocontext_i;
    logic                           notime_i;
    logic                           tc_branch_i;
    logic                           tc_branch_taken_i;
    logic [1:0]                     priv_i;
    logic [XLEN-1:0]                iaddr_i;
    logic                           lc_tc_mux_i;
    logic                           thaddr_i;
    logic [XLEN-1:2]                tvec_i;
    logic [XLEN:0]                  lc_epc_i;
    logic                           ienable_i;
    logic                           encoder_mode_i;
    qual_status_e                   qual_status_i;
    ioptions_e                      ioptions_i;
    logic                           lc_updiscon_i;
    logic [BRANCH_COUNT_LEN-1:0]    branches_i;
    logic [BRANCH_MAP_LEN-1:0]      branch_map_i;    

    // outputs
    logic                   packet_valid_o;
    logic [PAYLOAD_LEN-1:0] packet_payload_o;
    logic [P_LEN-1:0]       payload_length_o;
    logic                   branch_map_flush_o;

    // testing only output
    logic                   expected_packet_valid;
    logic [PAYLOAD_LEN-1:0] expected_packet_payload;
    logic [P_LEN-1:0]       expected_payload_length;
    logic                   expected_branch_map_flush;

    // iteration variable
    logic [31:0] i;

    // DUT instantiation
    trdb_packet_emitter DUT(
        .clk_i                    (clk_i),
        .rst_ni                   (reset),
        .valid_i                  (valid_i),
        .packet_format_i          (packet_format_i),
        .packet_f_sync_subformat_i(packet_subformat_i),
        .lc_cause_i               (lc_cause_i),
        .lc_tval_i                (lc_tval_i),
        .lc_interrupt_i           (lc_interrupt_i),
        .tc_cause_i               (tc_cause_i),
        .tc_tval_i                (tc_tval_i),
        .tc_interrupt_i           (tc_interrupt_i),
        .nocontext_i              (nocontext_i),
        .notime_i                 (notime_i),
        .tc_branch_i              (tc_branch_i),
        .tc_branch_taken_i        (tc_branch_taken_i),
        .priv_i                   (priv_i),
        .iaddr_i                  (iaddr_i),
        .lc_tc_mux_i              (lc_tc_mux_i),
        .thaddr_i                 (thaddr_i),
        .tvec_i                   (tvec_i),
        .lc_epc_i                 (lc_epc_i),
        .ienable_i                (ienable_i),
        .encoder_mode_i           (encoder_mode_i),
        .qual_status_i            (qual_status_i),
        .ioptions_i               (ioptions_i),
        .lc_updiscon_i            (lc_updiscon_i),
        .branches_i               (branches_i),
        .branch_map_i             (branch_map_i),
        .packet_valid_o           (packet_valid_o),
        .packet_payload_o         (packet_payload_o),
        .payload_length_o         (payload_length_o),
        .branch_map_flush_o       (branch_map_flush_o)
    );

    logic [:0] test_vector[1000:0];
    //     length of line    # of lines

    initial begin // reading test vector
        $readmemb("<nome_file>", test_vector);
        i = 0;
        reset = 1;  // set == 1 -> no reset each cycle
                    // set == 0 -> reset each cycle
    end

    always @(posedge clk) begin
        {valid_i,
        packet_format_i,
        packet_subformat_i,
        lc_cause_i,
        lc_tval_i,
        lc_interrupt_i,
        tc_cause_i,
        tc_tval_i,
        tc_interrupt_i,
        nocontext_i,
        notime_i,
        tc_branch_i,
        tc_branch_taken_i,
        priv_i,
        iaddr_i,
        lc_tc_mux_i,
        thaddr_i,
        tvec_i,
        lc_epc_i,
        ienable_i,
        encoder_mode_i,
        qual_status_i,
        ioptions_i,
        lc_updiscon_i,
        branches_i,
        branch_map_i,
        expected_packet_valid,
        expected_packet_payload,
        expected_payload_length,
        expected_branch_map_flush
        } = test_vector[i]; #10;
        
    end

    always_ff @(negedge clk) begin // prints the line if it's wrong
        // packet_valid_o
        if(expected_packet_valid !== packet_valid_o) begin
            $display("Wrong valid: %b!=%b", expected_packet_valid, packet_valid_o);
        end
        // packet_payload_o
        if(expected_packet_payload !== packet_payload_o) begin
            $display("Wrong payload: %b!=%b", expected_packet_payload, packet_payload_o);
        end
        // payload_length_o
        if(expected_payload_length !== payload_length_o) begin
            $display("Wrong payload length: %b!=%b", expected_payload_length, payload_length_o);
        end
        // branch_map_flush_o
        if(expected_branch_map_flush !== branch_map_flush_o) begin
            $display("Wrong branch map flush: %b!=%b", expected_branch_map_flush, branch_map_flush_o);
        end
        // index increase
        i = i + 1;
    end

    always begin
        clk <= 1; #5;
        clk <= 0; #5;
    end





endmodule