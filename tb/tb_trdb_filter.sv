// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

`timescale 1ns/1ns

import trdb_pkg::*;

module tb_trdb_filter();

    logic clk;
    logic reset;

    // inputs
    // cause
    logic                   cause_filter_i;
    logic [CAUSE_LEN-1:0]   upper_cause_i;
    logic [CAUSE_LEN-1:0]   lower_cause_i;
    logic [CAUSE_LEN-1:0]   match_cause_i;
    logic                   cause_range_mode_i;
    logic                   cause_equal_mode_i;
    logic [CAUSE_LEN-1:0]   cause_i;
    // tvec
    logic                   tvec_filter_i;
    logic [XLEN-1:2]        upper_tvec_i;
    logic [XLEN-1:2]        lower_tvec_i;
    logic [XLEN-1:2]        match_tvec_i;
    logic                   tvec_range_mode_i;
    logic                   tvec_equal_mode_i;
    logic [XLEN-1:2]        tvec_i;
    // tval
    logic                   tval_filter_i;
    logic [XLEN-1:0]        upper_tval_i;
    logic [XLEN-1:0]        lower_tval_i;
    logic [XLEN-1:0]        match_tval_i;
    logic                   tval_range_mode_i;
    logic                   tval_equal_mode_i;
    logic [XLEN-1:0]        tval_i;
    // priv_lvl
    logic                   priv_lvl_filter_i;
    logic [PRIV_LEN-1:0]    upper_priv_lvl_i;
    logic [PRIV_LEN-1:0]    lower_priv_lvl_i;
    logic [PRIV_LEN-1:0]    match_priv_lvl_i;
    logic                   priv_lvl_range_mode_i;
    logic                   priv_lvl_equal_mode_i;
    logic [PRIV_LEN-1:0]    priv_lvl_i;
    // iaddr (pc)
    logic                   iaddr_filter_i;
    logic [XLEN-1:0]        upper_iaddr_i;
    logic [XLEN-1:0]        lower_iaddr_i;
    logic [XLEN-1:0]        match_iaddr_i;
    logic                   iaddr_range_mode_i;
    logic                   iaddr_equal_mode_i;
    logic [XLEN-1:0]        iaddr_i;

    // outputs
    logic                   nc_qualified_o;

    // testing output
    logic                   expected_nc_qualified;

    // iteration variable
    logic [31:0] i;

    // DUT instantiation
    trdb_filter DUT(
        .cause_filter_i(cause_filter_i),
        .upper_cause_i(upper_cause_i),
        .lower_cause_i(lower_cause_i),
        .match_cause_i(match_cause_i),
        .cause_range_mode_i(cause_range_mode_i),
        .cause_equal_mode_i(cause_equal_mode_i),
        .cause_i(cause_i),
        .tvec_filter_i(tvec_filter_i),
        .upper_tvec_i(upper_tvec_i),
        .lower_tvec_i(lower_tvec_i),
        .match_tvec_i(match_tvec_i),
        .tvec_range_mode_i(tvec_range_mode_i),
        .tvec_equal_mode_i(tvec_equal_mode_i),
        .tvec_i(tvec_i),
        .tval_filter_i(tval_filter_i),
        .upper_tval_i(upper_tval_i),
        .lower_tval_i(lower_tval_i),
        .match_tval_i(match_tval_i),
        .tval_range_mode_i(tval_range_mode_i),
        .tval_equal_mode_i(tval_equal_mode_i),
        .tval_i(tval_i),
        .priv_lvl_filter_i(priv_lvl_filter_i),
        .upper_priv_lvl_i(upper_priv_lvl_i),
        .lower_priv_lvl_i(lower_priv_lvl_i),
        .match_priv_lvl_i(match_priv_lvl_i),
        .priv_lvl_range_mode_i(priv_lvl_range_mode_i),
        .priv_lvl_equal_mode_i(priv_lvl_equal_mode_i),
        .priv_lvl_i(priv_lvl_i),
        .iaddr_filter_i(iaddr_filter_i),
        .upper_iaddr_i(upper_iaddr_i),
        .lower_iaddr_i(lower_iaddr_i),
        .match_iaddr_i(match_iaddr_i),
        .iaddr_range_mode_i(iaddr_range_mode_i),
        .iaddr_equal_mode_i(iaddr_equal_mode_i),
        .iaddr_i(iaddr_i),
        .nc_qualified_o(nc_qualified_o)
    );

    logic [NN:0] test_vector[1000:0];

    initial begin // reading test vector
        $readmemb("tv_trdb_filter", test_vector);
            i = 0;
            //reset = 0; #10;
            reset = 1;  // set == 1 -> no reset each cycle
                        // set == 0 -> reset each cycle
    end

    always @(posedge clk) begin
        {
            cause_filter_i,
            upper_cause_i,
            lower_cause_i,
            match_cause_i,
            cause_range_mode_i,
            cause_equal_mode_i,
            cause_i,
            tvec_filter_i,
            upper_tvec_i,
            lower_tvec_i,
            match_tvec_i,
            tvec_range_mode_i,
            tvec_equal_mode_i,
            tvec_i,
            tval_filter_i,
            upper_tval_i,
            lower_tval_i,
            match_tval_i,
            tval_range_mode_i,
            tval_equal_mode_i,
            tval_i,
            priv_lvl_filter_i,
            upper_priv_lvl_i,
            lower_priv_lvl_i,
            match_priv_lvl_i,
            priv_lvl_range_mode_i,
            priv_lvl_equal_mode_i,
            priv_lvl_i,
            iaddr_filter_i,
            upper_iaddr_i,
            lower_iaddr_i,
            match_iaddr_i,
            iaddr_range_mode_i,
            iaddr_equal_mode_i,
            iaddr_i,
            expected_nc_qualified
        } = test_vector[i]; #10;
    end

    always @(negedge clk) begin
        if (expected_nc_qualified !== nc_qualified_o) begin
            $display("Wrong qualified: %b!=%b", expected_nc_qualified, nc_qualified_o);
        end

        // index increase
        i = i + 1;
    end

    always begin 
        clk <= 1; #5;
        clk <= 0; #5;
    end

endmodule