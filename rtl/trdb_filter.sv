// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* FILTER MODULE */
/*
it declares instructions qualified or not
*/

import trdb_pkg::*;

module trdb_filter
(
    /*
    The idea is to have all inputs to be filtered in range or match.
    To achieve this, the filter requires for each parameter:
        - enable
        - upper and lower values
        - to be matched value
        - select between in range or match
        - qualified for each mode

    The trace to be qualified according to the filters set it requires 
    an AND between the qualified of the parameters to filter.
    */

    // parameters to filter
    // cause
    input logic                 cause_filter_i,
    input logic [CAUSE_LEN-1:0] upper_cause_i,
    input logic [CAUSE_LEN-1:0] lower_cause_i,
    input logic [CAUSE_LEN-1:0] match_cause_i,
    input logic                 cause_range_mode_i,
    input logic                 cause_equal_mode_i,
    input logic [CAUSE_LEN-1:0] cause_i,
    // tvec
    input logic                 tvec_filter_i,
    input logic [XLEN-1:2]      upper_tvec_i,
    input logic [XLEN-1:2]      lower_tvec_i,
    input logic [XLEN-1:2]      match_tvec_i,
    input logic                 tvec_range_mode_i,
    input logic                 tvec_equal_mode_i,
    input logic [XLEN-1:2]      tvec_i,
    // tval
    input logic                 tval_filter_i,
    input logic [XLEN-1:0]      upper_tval_i,
    input logic [XLEN-1:0]      lower_tval_i,
    input logic [XLEN-1:0]      match_tval_i,
    input logic                 tval_range_mode_i,
    input logic                 tval_equal_mode_i,
    input logic [XLEN-1:0]      tval_i,
    // priv_lvl
    input logic                 priv_lvl_filter_i,
    input logic [XLEN-1:2]      upper_priv_lvl_i,
    input logic [XLEN-1:2]      lower_priv_lvl_i,
    input logic [XLEN-1:2]      match_priv_lvl_i,
    input logic                 priv_lvl_range_mode_i,
    input logic                 priv_lvl_equal_mode_i,
    input logic [XLEN-1:2]      priv_lvl_i,
    // iaddr (pc)
    input logic                 iaddr_filter_i,
    input logic [XLEN-1:2]      upper_iaddr_i,
    input logic [XLEN-1:2]      lower_iaddr_i,
    input logic [XLEN-1:2]      match_iaddr_i,
    input logic                 iaddr_range_mode_i,
    input logic                 iaddr_equal_mode_i,
    input logic [XLEN-1:2]      iaddr_i,

    output logic                nc_qualified_o
);

    // output signals for comparators
    // cause
    logic cause_in_range;
    logic cause_equals;
    // tvec
    logic tvec_in_range;
    logic tvec_equals;
    // tval
    logic tval_in_range;
    logic tval_equals;
    // priv_lvl
    logic priv_lvl_in_range;
    logic priv_lvl_equals;
    // iaddr (pc)
    logic iaddr_in_range;
    logic iaddr_equals;

    // assignments
    // cause
    assign cause_in_range = cause_range_mode_i &&
                            cause_i < upper_cause_i &&
                            cause_i > lower_cause_i;
    assign cause_equals =   cause_equal_mode_i &&
                            cause_i == match_cause_i;
    // tvec
    assign tvec_in_range =  tvec_range_mode_i &&
                            tvec_i < upper_tvec_i &&
                            tvec_i > lower_tvec_i;
    assign tvec_equals =    tvec_equal_mode_i &&
                            tvec_i == match_tvec_i;
    // tval
    assign tval_in_range =  tval_range_mode_i &&
                            tval_i < upper_tval_i &&
                            tval_i > lower_tval_i;
    assign tval_equals =    tval_equal_mode_i &&
                            tval_i == match_tval_i;
    // priv_lvl
    assign priv_lvl_in_range =  priv_lvl_range_mode_i &&
                                priv_lvl_i < upper_priv_lvl_i &&
                                priv_lvl_i > lower_priv_lvl_i;
    assign priv_lvl_equals =    priv_lvl_equal_mode_i &&
                                priv_lvl_i == match_priv_lvl_i;
    // iaddr
    assign iaddr_in_range = iaddr_range_mode_i &&
                            iaddr_i < upper_iaddr_i &&
                            iaddr_i > lower_iaddr_i;
    assign iaddr_equals =   iaddr_equal_mode_i &&
                            iaddr_i == match_iaddr_i;

    // assigning output
    assign nc_qualified_o = ((cause_filter_i && (cause_in_range || cause_equals)) ||
                            ~cause_filter_i) && // cause
                            ((tvec_filter_i && (tvec_in_range || tvec_equals)) ||
                            ~tvec_filter_i) && // tvec
                            ((tval_filter_i && (tval_in_range || tval_equals)) ||
                            ~tval_filter_i) && // tval
                            ((priv_lvl_filter_i && (priv_lvl_in_range || priv_lvl_equals)) ||
                            ~priv_lvl_filter_i) && // priv_lvl
                            ((iaddr_filter_i && (iaddr_in_range || iaddr_equals)) ||
                            ~iaddr_filter_i); // iaddr

endmodule