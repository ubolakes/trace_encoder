// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

`timescale 1ns/1ns

import trdb_pkg::*;

module tb_trdb_priority();

    logic clk;
    logic reset;
    
    // inputs
    logic               valid_i;
    logic               lc_exception_i;
    logic               lc_updiscon_i;
    logic               tc_qualified_i;
    logic               tc_exception_i;
    logic               tc_retired_i;
    logic               tc_first_qualified_i;
    logic               tc_privchange_i;
    logic               tc_gt_max_resync_i;
    logic               tc_et_max_resync_i;
    logic               tc_branch_map_empty_i;
    logic               tc_branch_map_full_i;
    logic               tc_enc_enabled_i;
    logic               tc_enc_disabled_i;
    logic               tc_opmode_change_i;
    logic               lc_final_qualified_i;
    logic               nc_exception_i;
    logic               nc_privchange_i;
    logic               nc_branch_map_empty_i;
    logic               nc_qualified_i;
    logic               nc_retired_i;
    logic [XLEN-1:0]    addr_to_compress_i;

    // outputs
    logic valid_o;
    trdb_format_e           format_o;
    trdb_f_sync_subformat_e subformat_o;
    logic                   thaddr_o;
    logic                   lc_tc_mux_o;
    logic                   resync_timer_rst_o;
    qual_status_e           qual_status_o;
    logic [$clog2(XLEN):0]  keep_bits_o;

    //testing only output
    logic                   expected_valid;
    trdb_format_e           expected_format;
    trdb_f_sync_subformat_e expected_subformat;
    logic                   expected_thaddr;
    logic                   expected_lc_tc_mux;
    logic                   expected_resync_timer_rst;
    qual_status_e           expected_qual_status;
    logic [$clog2(XLEN):0]  expected_keep_bits;
    
    // iteration variable
    logic [31:0] i;

    // DUT instantiation
    trdb_priority DUT(
        .clk_i                    (clk),
        .rst_ni                   (reset),
        .valid_i                  (valid_i),
        .lc_exception_i           (lc_exception_i),
        .lc_updiscon_i            (lc_updiscon_i),
        .tc_qualified_i           (tc_qualified_i),
        .tc_exception_i           (tc_exception_i),
        .tc_retired_i             (tc_retired_i),
        .tc_first_qualified_i     (tc_first_qualified_i),
        .tc_privchange_i          (tc_privchange_i),
        .tc_gt_max_resync_i       (tc_gt_max_resync_i),
        .tc_et_max_resync_i       (tc_et_max_resync_i),
        .tc_branch_map_empty_i    (tc_branch_map_empty_i),
        .tc_branch_map_full_i     (tc_branch_map_full_i),
        .tc_enc_enabled_i         (tc_enc_enabled_i),
        .tc_enc_disabled_i        (tc_enc_disabled_i),
        .tc_opmode_change_i       (tc_opmode_change_i),
        .lc_final_qualified_i     (lc_final_qualified_i),
        .nc_exception_i           (nc_exception_i),
        .nc_privchange_i          (nc_privchange_i),
        .nc_branch_map_empty_i    (nc_branch_map_empty_i),
        .nc_qualified_i           (nc_qualified_i),
        .nc_retired_i             (nc_retired_i),
        .addr_to_compress_i       (addr_to_compress_i),
        .valid_o                  (valid_o),
        .packet_format_o          (format_o),
        .packet_f_sync_subformat_o(subformat_o),
        .thaddr_o                 (thaddr_o),
        .lc_tc_mux_o              (lc_tc_mux_o),
        .resync_timer_rst_o       (resync_timer_rst_o),
        .qual_status_o            (qual_status_o),
        .keep_bits_o              (keep_bits_o)
    );

    logic [68:0] test_vector[1000:0];
    //     length of line    # of lines
    
    initial begin // reading test vector
        $readmemb("tv_trdb_priority", test_vector);
        i = 0;
        reset = 1;  // set == 1 -> no reset each cycle
                    // set == 0 -> reset each cycle
    end
    
    always @(posedge clk) begin // on posedge we get expected output
        {valid_i,
        lc_exception_i,
        lc_updiscon_i,
        tc_qualified_i,
        tc_exception_i,
        tc_retired_i,
        tc_first_qualified_i,
        tc_privchange_i,
        tc_gt_max_resync_i,
        tc_et_max_resync_i, 
        tc_branch_map_empty_i,
        tc_branch_map_full_i,
        tc_enc_enabled_i,
        tc_enc_disabled_i,
        tc_opmode_change_i,
        lc_final_qualified_i,
        nc_exception_i,
        nc_privchange_i,
        nc_branch_map_empty_i,
        nc_qualified_i,
        nc_retired_i,
        addr_to_compress_i,
        expected_valid,
        expected_format,
        expected_subformat,
        expected_thaddr,
        expected_lc_tc_mux,
        expected_resync_timer_rst,
        expected_qual_status,
        expected_keep_bits
        } = test_vector[i]; #10;
    end

    always @(negedge clk) begin// on negedge we compare the expected result with the actual one
        // valid_o
        if(expected_valid !== valid_o) begin
            $display("Wrong valid: %b!=%b", expected_valid, valid_o); // printed if it's wrong
        end        
        // format_o
        if(expected_format !== format_o) begin
            $display("Wrong format: %b!=%b", expected_format, format_o);
        end
        // subformat_o
        if(expected_subformat !== subformat_o) begin
            $display("Wrong subformat: %b!=%b", expected_subformat, subformat_o);
        end
        // thaddr_o
        if(expected_thaddr !== thaddr_o) begin
            $display("Wrong thaddr: %b!=%b", expected_thaddr, thaddr_o);
        end
        // lc_tc_mux_o
        if(expected_lc_tc_mux !== lc_tc_mux_o) begin
            $display("Wrong lc_tc_mux: %b!=%b", expected_lc_tc_mux, lc_tc_mux_o);
        end
        // resync_rst_o
        if(expected_resync_timer_rst !== resync_timer_rst_o) begin
            $display("Wrong resync_rst: %b!=%b", expected_resync_timer_rst, resync_timer_rst_o);
        end    
        // qual_status_o
        if(expected_qual_status !== qual_status_o) begin
            $display("Wrong qual_status: %b!=%b", expected_qual_status, qual_status_o);
        end
        // keep_bits_o
        if(expected_keep_bits !== keep_bits_o) begin
            $display("Wrong keep_bits: %b!=%b", expected_keep_bits, keep_bits_o);
        end

        // index increase
        i = i + 1; 
    end

    always
    begin
        clk <= 1; #5;
        clk <= 0; #5;
    end

endmodule