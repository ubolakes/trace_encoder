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
    input logic valid_i,

    /*  signals for the jump target cache
        not supported by snitch */
    input logic jtc_enabled_i, // must be supported and enabled by the CPU
    input logic address_in_cache_i, // communicates if the address is present in cache

    // refer to page 53 of the specs for clarification

    /*TO DO: determine width of signals, not all are logic*/

    // lc (last cycle) signals
    input logic lc_exception_i,
    input logic lc_updiscon_i, // updsicon == uninferable PC discontinuity

    // tc (this cycle) signals
    input logic tc_qualified_i,
    input logic tc_is_branch_i,
    input logic tc_exception_i,

    //input logic tc_exc_only_i, // not necessary a special input signal
    /* Exc_only meaning:
        Exception or interrupt signalled without
        simultaneous retirement.

        This means that in this cycle only the 
        exception signal is 1 and the number of 
        retired instructions is 0.
    */
    input logic tc_retired_i, // istr retired in tc
    // used to create tc_exc_only and er_n signal


    //input logic tc_reported_i, // what's the meaning? refer to page 51 of spec
    /* Reported meaning:
        The "exception previous" (i.e. the lc_exception)
        was reported in a packet with thaddr = 0 on the
        cycle it occured, beacause it was preceded by an
        updiscon OR immediately followed by another exception
    
        This means I need to consider the value of the previous
        packet and if its thaddr value was 0.
        The thaddr value appears only in 3.1 format packets.
        I need a signal like: "lc_thaddr" (last cycle thaddr),
        the value of this signal is the same as the parameter
        in the packet.    
    */
    
    //input logic lc_thaddr_i,
    /*  no need to have it as input, because it can be kept as
        a value inside the module*/


    input logic tc_first_qualified_i,
    input logic tc_privchange_i,
    input logic tc_precise_context_report_i,
    input logic tc_context_change_i, // determinable using a comparator with lc_context and tc_context
    input logic tc_context_report_as_disc_i, // understand the meaning
    input logic tc_max_resync_i, // resync timer expired
    input logic tc_branch_map_empty_i,
    
    //input logic tc_er_n_i, // no need for a specific input signal
    /*er_n: exception and retirement in the same cycle*/

    /* rpt_br:  report branches due to full branch_map
                or misprediction    */
    input logic tc_branch_map_full_i,
    input logic tc_branch_misprediction_i, // signal to determine misprediction
    // branch prediction not supported by snitch

    // cci: imprecise context change
    input logic tc_imprecise_context_report_i, // optional
    
    // understand the meaning of branches and pbc in graph at page 53
    /*
    ppccd:  priv has changed OR context has changed
            and it needs to be reported precisely or
            treated as an updiscon
    */

    input logic tc_pbc_i, // correctly predicted branch count, not supported by snitch

    // format 3 subformat 3 - NOT shown in graph
    input logic tc_enc_enabled_i,
    input logic tc_enc_disabled_i,
    input logic tc_opmode_change_i,
    input logic lc_final_qualified_instr_i,
    input logic tc_packets_lost_i,


    // nc (next cycle) signals
    input logic nc_exception_i,
    input logic nc_privchange_i,
    input logic nc_context_change_i,
    input logic nc_precise_context_report_i,
    input logic nc_context_report_as_disc_i,
    input logic nc_branch_map_empty_i,
    input logic nc_qualified_i,

    input logic nc_retired_i, // used w/nc_exception for signal nc_exc_only

    /* 
    ppccd_br:   priv has changed OR context has changed
                and it needs to be reported precisely or
                treated as an updiscon AND branch map is
                not empty
    no need for a dedicated input signal
    Signals required already present
    */


    /* Precise/imprecise context report: refer to page 22 of the spec
        Precise:    required the address of the first instr retired
                    AND the new context.
                    Unreported branches must be reported first.

        Imprecise:  required the new context value
    */

    // trigger input
    input logic [3:0] trigger_i,
    /* if it's value is 4, it's used to request a format 2 packet */
    // add signal to generate a type 2 packet

    output logic notify_o,
    // communicates the packet emitter that format 2 packet was requested by trigger unit


    output logic                        valid_o,
    output trdb_format_e                packet_format_o,
    output trdb_f_sync_subformat_e      packet_f_sync_subformat_o,
    output trdb_f_opt_ext_subformat_e   packet_f_opt_ext_subformat_o // this signal is useless for snitch, since it doesn't support jtc and branch prediction
    );

    /* signals required for packet determination */
    // last cycle
    logic   lc_thaddr_d;
    logic   lc_thaddr_q; // 1 cycle delayed
    
    /*  Dubbio: se lo imposto ad un valore non rischio di causare 
        generazioni di pacchetti sbagliate.
        Se invece lo lascio non definito non è meglio?
        Visto che il valore che causa una scelta è lo 0,
        ha senso resettare a 1? */
    /*  Di quanti cicli la ritardo?
        Perchè nel top level i segnali lc sono ritardi di due cicli
        rispetto all'input, però qui mi interessa un solo ciclo*/
    
    always_ff @( posedge clk_i, negedge rst_ni ) begin : delayed_thaddr
        if(~rst_ni) begin
            lc_thaddr_q <= '1;
        end else begin
            lc_thaddr_q <= thaddr_d;
        end
    end
    
    // this cycle
    logic   tc_exc_only; // for a precise definition: page 51 of the spec
    logic   tc_reported; // ibidem
    logic   tc_ppccd; // ibidem
    logic   tc_resync_br; // ibidem
    logic   tc_er_n; // ibidem
    logic   tc_rpt_br; // ibidem
    logic   tc_cci; // ibidem

    // next cycle
    logic   nc_exc_only;
    logic   nc_ppccd_br;


    // value assignment
    assign  tc_exc_only     = tc_exception_i && ~tc_retired_i;
    assign  tc_reported     = lc_exception_i && ~lc_thaddr_q;
    assign  tc_ppccd        = tc_priv_change_i || (tc_context_change_i && 
                                (tc_precise_context_report_i ||
                                tc_context_report_as_disc_i));
    assign  tc_resync_br    = tc_max_resync_i && ~tc_branch_map_empty_i;
    assign  tc_er_n         = tc_exception_i && tc_retired_i;
    assign  tc_rpt_br       = tc_branch_map_full_i || tc_branch_misprediction_i;
    assign  tc_cci          = tc_context_change_i && tc_imprecise_context_report_i;
    assign  nc_exc_only     = nc_exception_i && ~nc_retired_i;
    assign  nc_ppccd_br     = (nc_privchange_i || (nc_context_change_i && 
                                (nc_precise_context_report_i || nc_context_report_as_disc_i))) && 
                                ~nc_branch_map_empty_i;
    assign  tc_f3_sf3       = tc_enc_enabled_i || tc_enc_disabled_i || tc_opmode_change_i ||
                                lc_final_qualified_instr_i || tc_packets_lost_i;


    /* combinatorial network to determine packet format */
    // refer to flowchart at page 53 of the spec
    always_comb begin : select_packet_format
        // default init values
        valid_o = '0;
        packet_format_o = F_OPT_EXT;
        packet_f_sync_subformat_o = SF_START;
        packet_f_opt_ext_subformat_o = SF_PBC;
        notify_o = '0;

        if( valid_i) begin
            // format 3 subformat 3 packet generation
            if(tc_f3_sf3) begin
                packet_format_o = F_SYNC;
                packet_f_sync_subformat_o = SF_SUPPORT;
                /* refer to the spec for the payload required*/
                valid_o = '1;
            end else if(tc_qualified_i) begin
                /*  update branch map?
                    here or in packet emitter?
                    Maybe:  send signals to packet emitter
                            to perform the update
                    TBD */
                if(lc_exception_i) begin
                    if(tc_exc_only) begin
                        packet_format_o = F_SYNC;
                        packet_f_sync_subformat_o = SF_TRAP;
                        /* thaddr_d = 0; resync_cnt = 0
                        cause = lc_cause_i; tval = lc_tval*/
                        valid_o = '1;
                    end else if(tc_reported) begin
                        packet_format_o = F_SYNC;
                        packet_f_sync_subformat_o = SF_START;
                        // resync_cnt = 0
                        valid_o = '1;
                    end else begin // not reported
                        packet_format_o = F_SYNC;
                        packet_f_sync_subformat_o = SF_TRAP;
                        /*thaddr_d = 1; resync_cnt = 0
                        cause = lc_cause_i; tval = lc_tval */ 
                        valid_o = '1;
                        end
                end else if(tc_first_qualified_i || tc_ppccd || tc_max_resync_i) begin
                    packet_format_o = F_SYNC;
                    packet_f_sync_subformat_o = SF_START;
                    //resync_cnt = 0
                    //check if packet requested by trigger unit
                    if(tc_precise_context_report_i || tc_context_report_as_disc_i) begin
                        notify_o = '1;
                    end
                    valid_o = '1;
                end else if(lc_updiscon_i) begin
                    if(tc_exc_only) begin
                        packet_format_o = F_SYNC;
                        packet_f_sync_subformat_o = SF_TRAP;
                        /* thaddr = 0; resync_cnt = 0
                        cause = tc_cause_i; tval = tc_tval  */
                        valid_o = '1;
                    end else begin
                        /* choosing between format 0/1/2 */
                        if(tc_pbc_i >= 31) begin
                        packet_format_o = F_OPT_EXT;
                        packet_f_opt_ext_subformat_o = SF_JTC;
                        /* format 0 subformat 0
                        value for payload TBD */
                        valid_o = '1;
                        end else if(jtc_enabled_i && address_in_cache_i) begin
                            packet_format_o = F_OPT_EXT;
                            packet_f_opt_ext_subformat_o = SF_JTC;
                            /* value for payload TBD */
                            valid_o = '1;
                        end else if(!tc_branch_map_empty) begin
                            packet_format_o = F_DIFF_DELTA;
                            /* value for payload TBD */
                            valid_o = '1;
                        end else begin // branch count == 0
                            packet_format_o = F_ADDR_ONLY;
                            /* value for payload TBD */
                            valid_o = '1;
                        end
                    end
                end else if(tc_resync_br || tc_er_n) begin
                    /* choosing between format 0/1/2 */
                    if(tc_pbc_i >= 31) begin
                        packet_format_o = F_OPT_EXT;
                        packet_f_opt_ext_subformat_o = SF_JTC;
                        /* value for payload TBD */
                        valid_o = '1;
                    end else if(jtc_enabled_i && address_in_cache_i) begin
                        packet_format_o = F_OPT_EXT;
                        packet_f_opt_ext_subformat_o = SF_JTC;
                        /* value for payload TBD */
                        valid_o = '1;
                    end else if(!tc_branch_map_empty) begin
                        packet_format_o = F_DIFF_DELTA;
                        /* value for payload TBD */
                        valid_o = '1;
                    end else begin // branch count == 0
                        packet_format_o = F_ADDR_ONLY;
                        /* value for payload TBD */
                        valid_o = '1;
                    end
                end else if(nc_exc_only || nc_ppccd_br || !nc_qualified_i) begin
                    /* choosing between format 0/1/2 */
                    if(tc_pbc_i >= 31) begin
                        packet_format_o = F_OPT_EXT;
                        packet_f_opt_ext_subformat_o = SF_JTC;
                        /* value for payload TBD */
                        valid_o = '1;
                    end else if(jtc_enabled_i && address_in_cache_i) begin
                        packet_format_o = F_OPT_EXT;
                        packet_f_opt_ext_subformat_o = SF_JTC;
                        /* value for payload TBD */
                        valid_o = '1;
                    end else if(!tc_branch_map_empty) begin
                        packet_format_o = F_DIFF_DELTA;
                        /* value for payload TBD */
                        valid_o = '1;
                    end else begin // branch count == 0
                        packet_format_o = F_ADDR_ONLY;
                        /* value for payload TBD */
                        valid_o = '1;
                    end
                    // check if packet was requested by trigger unit
                    if(nc_precise_context_report_i || nc_context_report_as_disc_i) begin
                        notify_o = '1;
                    end
                end else if(tc_rpt_br) begin
                    if(tc_pbc_i >= 31) begin
                        packet_format_o = F_OPT_EXT;
                        packet_f_opt_ext_subformat_o = SF_PBC;
                        valid_o = '1;
                    end else
                        packet_format_o = F_DIFF_DELTA;
                end else if(tc_cci) begin
                    packet_format_o = F_SYNC;
                    packet_f_sync_subformat_o = SF_CONTEXT;
                    notify_o = '1; // requested by trigger unit
                    valid_o = '1;
                end
            end
        end
    end



endmodule