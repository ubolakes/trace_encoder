/*PRIORITY*/
/*
change this module name to a more appropriate one
for example "packet identifier" or something similar
*/
/*
it orders packet generation request by priority
*/

import trdb_pkg::*;

module trdb_priority (

    input logic clk_i,
    input logic rst_ni,

    input logic valid_i,

    /*  signals for the jump target cache mode - non mandatory */
    //input logic jtc_enabled_i,
    //input logic address_in_cache_i, // communicates if the address is present in cache

    // refer to page 53 of the specs for clarification

    /*TODO: determine width of signals, not all are logic*/

    // lc (last cycle) signals
    input logic lc_exception_i,
    input logic lc_updiscon_i, // updsicon == uninferable PC discontinuity

    // tc (this cycle) signals
    input logic tc_qualified_i,
    input logic tc_exception_i,

    input logic tc_retired_i, // istr retired in tc
    // used to create tc_exc_only and er_n signal
    
    input logic tc_first_qualified_i,
    input logic tc_privchange_i,
    //input logic tc_precise_context_report_i,  // requires ctype signal CPU side
    input logic tc_context_change_i,          // ibidem
    //input logic tc_context_report_as_disc_i,  // ibidem
    input logic tc_gt_max_resync_i, // greater than timeout
    input logic tc_et_max_resync_i, // one step to timeout
    input logic tc_branch_map_empty_i,
    
    input logic tc_branch_map_full_i,
    //input logic tc_branch_misprediction_i, // non mandatory

    //input logic tc_imprecise_context_report_i, // requires ctype signal CPU side

    //input logic tc_pbc_i, // correctly predicted branch count, non mandatory

    // format 3 subformat 3 - NOT shown in graph
    input logic tc_enc_enabled_i,
    input logic tc_enc_disabled_i,
    input logic tc_opmode_change_i,
    input logic lc_final_qualified_i,
    //input logic tc_packets_lost_i, // non mandatory


    // nc (next cycle) signals
    input logic nc_exception_i,
    input logic nc_privchange_i,
    input logic nc_context_change_i,
    //input logic nc_precise_context_report_i,  // requires ctype signal CPU side
    //input logic nc_context_report_as_disc_i,  // ibidem
    input logic nc_branch_map_empty_i,
    input logic nc_qualified_i,

    input logic nc_retired_i, // used w/nc_exception for signal nc_exc_only

    // non mandatory sideband signals
    // refer to page 52 of the spec
    //input logic halted_i,
    //input logic reset_i,

    // inputs for irreport and irdepth, non mandatory
    //input logic implicit_return_i, // tells if the mode is enabled
    //input logic [:0] call_counter_size_i, // size of nested calls counter, 2^value
    //input logic [:0] return_stack_size_i, // size of nested calls stack, 2^value

    // trigger unit request ports, must be supported by the CPU
    //input logic tc_trigger_req_i,
    //output logic notify_o,
    // communicates the packet emitter that format 2 packet was requested by trigger unit

    output logic                                valid_o,
    output trdb_format_e                        packet_format_o,
    output trdb_f_sync_subformat_e              packet_f_sync_subformat_o,
    //output trdb_f_opt_ext_subformat_e         packet_f_opt_ext_subformat_o, // non mandatory, used for jtc and branch prediction
    output logic                                thaddr_o, // required for f3 sf1 packet payload
    output logic                                cause_mux_o, // operates the MUX to choose between lc or tc cause: 0 -> lc, 1 -> tc
    output logic                                tval_mux_o, // operates the MUX to choose between lc or tc tval: 0 -> lc, 1 -> tc
    output logic                                resync_timer_rst_o, // resets counter
    output qual_status_e                        qual_status_o
    //output logic                                irreport_o, // non mandatory, required implicit return mode
    );


    /* internal signals required for packet determination */
    // last cycle
    logic   lc_ended_ntr_d, lc_ended_ntr_q;
    logic   lc_ended_rep_d, lc_ended_rep_q;
    // this cycle
    logic   tc_exc_only; // for a precise definition: page 51 of the spec
    logic   tc_ppccd; // ibidem
    logic   tc_resync_br; // ibidem
    logic   tc_er_n; // ibidem
    logic   tc_rpt_br; // ibidem
    //logic   tc_cci; // ibidem
    logic   tc_reported_d, tc_reported_q; // ibidem

    // next cycle
    logic   nc_exc_only;
    logic   nc_ppccd_br;


    // value assignment
    assign  tc_exc_only     = tc_exception_i && ~tc_retired_i;
    assign  tc_ppccd        = tc_privchange_i || (tc_context_change_i /*&& 
                                (tc_precise_context_report_i ||
                                tc_context_report_as_disc_i)*/);
    assign  tc_resync_br    = tc_et_max_resync_i && ~tc_branch_map_empty_i;
    assign  tc_er_n         = (tc_exception_i && tc_retired_i) /*|| tc_trigger_req_i*/;
    assign  tc_rpt_br       = tc_branch_map_full_i /* || tc_branch_misprediction_i*/;
    //assign  tc_cci          = tc_context_change_i && tc_imprecise_context_report_i;
    assign  nc_exc_only     = nc_exception_i && ~nc_retired_i;
    assign  nc_ppccd_br     = (nc_privchange_i || (nc_context_change_i /*&&
                                (nc_precise_context_report_i || nc_context_report_as_disc_i)*/)) && 
                                ~nc_branch_map_empty_i;
    assign  tc_f3_sf3       = tc_enc_enabled_i || tc_enc_disabled_i || tc_opmode_change_i ||
                                lc_final_qualified_i /*|| tc_packets_lost_i*/;

    /*  
    The reset value is 0, the spec doesn't say how to behave.
    The 0 value specifies an exception w/out retired instr 
    in this cycle and an exception in the previous cycle.
    */
    always_ff @( posedge clk_i, negedge rst_ni ) begin
        if(~rst_ni) begin
            tc_reported_q <= '0;
            lc_ended_ntr_q <= '0;
            lc_ended_rep_q <= '0;
        end else begin
            tc_reported_q <= tc_reported_d;
            lc_ended_ntr_q <= lc_ended_ntr_d;
            lc_ended_rep_q <= lc_ended_rep_d;
        end
    end

    /*TODO: add condition to determine if F2, F1, F0SF0 are requested by the trigger unit*/

    /* combinatorial network to determine packet format */
    // refer to flowchart at page 53 of the spec
    always_comb begin : select_packet_format
        // default init values
        valid_o = '0;
        packet_format_o = F_OPT_EXT;
        packet_f_sync_subformat_o = SF_START;
        //packet_f_opt_ext_subformat_o = SF_PBC;
        //notify_o = '0;
        thaddr_o = '0;
        cause_mux_o = '0;
        resync_timer_rst_o = '0;
        tval_mux_o = '0;
        tc_reported_d = '0;
        qual_status_o = NO_CHANGE;
        lc_ended_ntr_d = '0;
        lc_ended_rep_d = '0;
        
        if(valid_i) begin
            // format 3 subformat 3 packet generation
            /*  this if is not in the flowchart, but it's only described.
                To me it made more sense to have it as the first if. */
            if(tc_f3_sf3) begin
                packet_format_o = F_SYNC;
                packet_f_sync_subformat_o = SF_SUPPORT;
                // if-then-else to determine qual_status value for payload
                if(lc_ended_ntr_q == '1) begin
                    qual_status_o = ENDED_NTR;
                end else if(lc_ended_rep_q == '1) begin
                    qual_status_o = ENDED_REP;
                end else if(tc_packets_lost_i == '1) begin
                    qual_status_o = TRACE_LOST;
                end
                valid_o = '1;
            /* TODO:    if for halted and reset sideband signals,
                        if at least one asserted -> considers unqualified*/  
            end else if(tc_qualified_i) begin
                if(lc_exception_i) begin
                    if(tc_exc_only) begin
                        packet_format_o = F_SYNC;
                        packet_f_sync_subformat_o = SF_TRAP;
                        resync_timer_rst_o = '1;
                        cause_mux_o = 0;
                        tval_mux_o = '0;
                        tc_reported_d = '1;
                        thaddr_o = '0;
                        /* thaddr_d = 0; resync_cnt = 0
                        cause = lc_cause_i; tval = lc_tval*/
                        valid_o = '1;
                    end else if(tc_reported_q) begin
                        packet_format_o = F_SYNC;
                        packet_f_sync_subformat_o = SF_START;
                        resync_timer_rst_o = '1;
                        // resync_cnt = 0
                        valid_o = '1;
                    end else begin // not reported
                        packet_format_o = F_SYNC;
                        packet_f_sync_subformat_o = SF_TRAP;
                        resync_timer_rst_o = '1;
                        cause_mux_o = '0;
                        tval_mux_o = '0;
                        thaddr_o = '1;
                        /*thaddr_d = 1; resync_cnt = 0
                        cause = lc_cause_i; tval = lc_tval */ 
                        valid_o = '1;
                        end
                end else if(tc_first_qualified_i || tc_ppccd || tc_gt_max_resync_i) begin
                    packet_format_o = F_SYNC;
                    packet_f_sync_subformat_o = SF_START;
                    resync_timer_rst_o = '1;
                    //resync_cnt = 0
                    valid_o = '1;
                end else if(lc_updiscon_i) begin
                    // packet generated due to updiscon
                    lc_ended_ntr_d = '1;
                    if(tc_exc_only) begin
                        packet_format_o = F_SYNC;
                        packet_f_sync_subformat_o = SF_TRAP;
                        thaddr_o = '0;
                        resync_timer_rst_o = '1;
                        cause_mux_o = '1;
                        tval_mux_o = '1;
                        /* thaddr = 0; resync_cnt = 0
                        cause = tc_cause_i; tval = tc_tval  */
                        valid_o = '1;
                    end else begin
                        /* choosing between format 0/1/2 */
                        /*if(tc_pbc_i >= 31) begin // format 0 subformat 0
                        packet_format_o = F_OPT_EXT;
                        packet_f_opt_ext_subformat_o = SF_JTC;
                        // value for payload TBD
                        end else if(jtc_enabled_i && address_in_cache_i) begin // format 0 subformat 1
                            packet_format_o = F_OPT_EXT;
                            packet_f_opt_ext_subformat_o = SF_JTC;
                            // value for payload TBD
                        end else*/ if(!tc_branch_map_empty_i) begin
                            packet_format_o = F_DIFF_DELTA;
                        end else begin // branch count == 0
                            packet_format_o = F_ADDR_ONLY;
                        end
                        valid_o = '1;
                    end
                end else if(tc_resync_br || tc_er_n) begin
                    // non mandatory 
                    /* if(tc_er_n && tc_trigger_req_i) begin // requested from trigger unit
                        notify_o = '1;
                    end */
                    
                    /* choosing between format 0/1/2 */
                    /*if(tc_pbc_i >= 31) begin
                        packet_format_o = F_OPT_EXT;
                        packet_f_opt_ext_subformat_o = SF_JTC;
                        // value for payload TBD
                    end else if(jtc_enabled_i && address_in_cache_i) begin
                        packet_format_o = F_OPT_EXT;
                        packet_f_opt_ext_subformat_o = SF_JTC;
                        // value for payload TBD
                    end else*/ if(!tc_branch_map_empty_i) begin
                        packet_format_o = F_DIFF_DELTA;
                    end else begin // branch count == 0
                        packet_format_o = F_ADDR_ONLY;
                    end
                    valid_o = '1;
                end else if(nc_exc_only || nc_ppccd_br || !nc_qualified_i) begin
                    if(!nc_qualified_i) begin
                        // the packet is sent because it's the last instr qualified
                        lc_ended_rep_d = '1;
                    end
                    /* choosing between format 0/1/2 */
                    /*if(tc_pbc_i >= 31) begin
                        packet_format_o = F_OPT_EXT;
                        packet_f_opt_ext_subformat_o = SF_JTC;
                        // value for payload TBD
                    end else if(jtc_enabled_i && address_in_cache_i) begin
                        packet_format_o = F_OPT_EXT;
                        packet_f_opt_ext_subformat_o = SF_JTC;
                        // value for payload TBD
                    end else*/ if(!tc_branch_map_empty_i) begin
                        packet_format_o = F_DIFF_DELTA;
                    end else begin // branch count == 0
                        packet_format_o = F_ADDR_ONLY;
                    end
                    valid_o = '1;
                end else if(tc_rpt_br) begin
                    /* // non mandatory, requires support for jtc and branch prediction
                    if(tc_pbc_i >= 31) begin
                        packet_format_o = F_OPT_EXT;
                        packet_f_opt_ext_subformat_o = SF_PBC;
                        valid_o = '1;
                    end else begin*/
                        packet_format_o = F_DIFF_DELTA;
                        valid_o = '1;
                    //end
                end /*else if(tc_cci) begin // non mandatory, requires support for context
                    packet_format_o = F_SYNC;
                    packet_f_sync_subformat_o = SF_CONTEXT;
                    valid_o = '1;
                end*/
            end
        end
    end



endmodule