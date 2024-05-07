/* TOP LEVEL MODULE */

module trace_debugger import trdb_pkg::*;
    #(parameter APB_ADDR_WIDTH = 32)
(
    input logic clk_i,
    input logic rst_ni,
    input logic test_mode_i,

    /* data from the CPU */
    /*
    - number of instr retired
    - if there was an interrupt or exception
    - cause of the exception/interrupt and trap value
    - privilege level
    - instr type
    - instr address
    */
    // mandatory inputs
    //TODO: input signal to determine if I can read: valid_i
    input logic iretired_i, // core_events_o.retired_i 
    input logic exception_i, // exception
    input logic interrupt_i, // cause_irq_q - used with the previous one to discriminate interrupt from exception
    input logic [CAUSE_LEN:0] cause_i, // cause_q
    input logic [TVEC_LEN:0] tvec_i, // tvec_q, contains trap handler address
    input logic [TVAL_LEN:0] tval_i, // not implemented in snitch, mandatory according to the spec
    input logic [PRIV_LEN:0] priv_lvl_i, // priv_lvl_q
    input logic [INST_LEN:0] inst_data_i, // inst_data
    //input logic compressed, // to discriminate compressed instructions from the others - in case the CPU supports C extension
    input logic [PC_LEN:0] pc_i, //pc_q - instruction address
    input logic [:0] epc_i, // epc_q, required for format 3 subformat 1
    input logic [3:0] trigger_i,
    //input logic [1:0] ctype_i, // according to the spec it's 1 or 2 bit wide, supported by CPU
    // here it's 2 bit for better future compatibility


    // outputs
    // info needed for the encapsulator
    output logic [PTYPE_LEN:0]packet_type_o,
    output logic [P_LEN:0] packet_length_o, // in bytes
    output logic [PAYLOAD_LEN:0] packet_payload_o

    // TO-DO: add constants to trdb_pkg file

    // control signals for the module
);

    /* signals for management */
    // registers
    logic trace_activated;
    logic nocontext;
    logic notime;
    logic encoder_mode;
    logic delta_address;
    // filter
    logic trigger_trace_on; // hardwired to 0?
    logic trigger_trace_off; // hardwired to 0?
    //logic qualified; // is it needed or I can use qualified_d?
    logic trace_req_deactivate;
    // filter
    logic trace_valid; // TODO
    // priority
    logic packet_valid;
    trdb_format_e packet_format;
    trdb_f_sync_subformat_e packet_f_sync_subformat;
    logic thaddr;
    logic cause_mux;
    logic tval_mux;
    qual_status_e qual_status;
    logic branch_map_flush;
    logic [BRANCH_MAP_LEN-1:0] branch_map;
    logic [BRANCH_COUNT_LEN-1:0] branch_count;
    




    // we have three phases, called last cycle (lc), this cycle (tc) and next
    // cycle (nc), based on which we make decision whether we need to emit a
    // packet or not.
    /* last cycle signals */
    logic                   lc_exception;
    logic                   lc_updiscon;
    logic [CAUSE_LEN-1:0]   lc_cause;
    logic [TVAL_LEN-1:0]    lc_tval;
    logic                   lc_qualified;
    /* this cycle signals */
    logic                   tc_qualified;
    logic                   tc_is_branch;
    logic                   tc_exception;
    logic                   tc_retired;
    logic                   tc_first_qualified;
    logic                   tc_privchange;
    logic                   tc_context_change; // non mandatory
    //logic                   tc_precise_context_report; // requires ctype signal CPU side
    //logic                   tc_context_report_as_disc; // ibidem
    //logic                   tc_no_context_report;      // ibidem
    //logic                   tc_imprecise_context_report; // ibidem
    logic                   tc_gt_max_resync;
    logic                   tc_et_max_resync;
    logic                   tc_branch_map_empty;
    logic                   tc_branch_map_full;
    //logic                   tc_branch_misprediction; // non mandatory
    logic                   tc_enc_enabled;
    logic                   tc_enc_disabled;
    logic                   tc_opmode_change;
    logic                   tc_final_qualified;
    //logic                   tc_packets_lost; // non mandatory
    logic [CAUSE_LEN-1:0]   tc_cause;
    logic [TVAL_LEN-1:0]    tc_tval;
    /* next cycle signals */
    logic                   nc_exception;
    logic                   nc_privchange;
    //logic                   nc_precise_context_report; // same as tc version
    //logic                   nc_context_report_as_disc; // same as tc version
    logic                   nc_branch_map_empty;
    logic                   nc_qualified;
    logic                   nc_retired;

    
    /* MANAGING LC, TC, NC SIGNALS */
    /*
    To manage lc, tc, nc signals I decided to use two 
    serially connected FFs.
            ___________                    ___________              
    sig0_d--| D     Q |--sig0_q == sig1_d--| D     Q |--sig1_q
      nc    |         |    tc              |         |    lc
            |   FF0   |                    |   FF1   |
            |_________|                    |_________|
    */


    /* SIGNALS RECAP
        - this cycle -> _d and _q
            signal is assigned with _q (or 0_q in case it has a lc version)

        - last cycle -> 0_d, 0_q and 1_d, 1_q
            signal is assigned with 1_q
    */

    /* signals for FFs */
    /* last cycle */
    logic                   exception0_d, exception0_q;
    logic                   exception1_d, exception1_q;
    logic                   updiscon0_d, updiscon0_q;
    logic                   updiscon1_d, updiscon1_q;
    logic [CAUSE_LEN-1:0]   cause0_d, cause0_q;
    logic [CAUSE_LEN-1:0]   cause1_d, cause1_q;
    logic [TVAL_LEN-1:0]    tval0_d, tval0_q;
    logic [TVAL_LEN-1:0]    tval1_d, tval1_q;
    logic                   qualified0_d, qualified0_q;
    logic                   qualified1_d, qualified1_q;
    logic                   final_qualified_d, final_qualified_q;

    /* this cycle */
    logic   is_branch_d, is_branch_q;
    logic   retired_d, retired_q;
    logic   privchange_d, privchange_q;
    logic   context_change_d, context_change_q; // non mandatory
    //logic   precise_context_report_d, precise_context_report_q; // requires ctype signal CPU side
    //logic   context_report_as_disc_d, context_report_as_disc_q; // ibidem
    //logic   no_context_report_d, no_context_report_q; // ibidem
    //logic   imprecise_context_report_d, imprecise_context_report_q; // ibidem
    
    logic   gt_max_resync_d, gt_max_resync_q;
    logic   et_max_resync_d, et_max_resync_q;
    // anche questo lo devo gestire nel ff?
    // direi di sì, perché altrimenti è avanti di un ciclo

    logic   branch_map_empty_d, branch_map_empty_q;
    logic   branch_map_full_d, branch_map_full_q;
    //logic   branch_misprediction_d, branch_misprediction_q; // non mandatory
    logic   enc_enabled_d, enc_enabled_q;
    logic   enc_disabled_d, enc_disabled_q;
    logic   opmode_change_d, opmode_change_q;
    //logic   packets_lost_d, packets_lost_q; // non mandatory


    /*  the following commented section has non mandatory signals
        for now it's commented
    */
 /* combinatorial network to define the following 
    signals from ctype:
    - tc_no_context_report_i        -> ctype == 0
    - tc_precise_context_report_i   -> ctype == 2
    - tc_context_report_as_disc_i   -> ctype == 3
    - tc_imprecise_context_report_i -> ctype == 1
    - nc_precise_context_report_i   -> ctype == 2
    - nc_context_report_as_disc_i   -> ctype == 3*/
    /*
    always_comb begin : ctype_manager
        case(ctype_i)
        2'h0: // no report - add signal        
            tc_no_context_report = '1;
        2'h1:
            tc_imprecise_context_report = '1;
        2'h2:
            tc_precise_context_report = '1;
        2'h3:
            tc_context_report_as_disc = '1;
        endcase
    end
    */

    /*TODO: create a trigger decoder that produces:
                - trigger_trace_on  -> 2
                - trigger_trace_off -> 3
                - trigger_notify    -> 4
    */
    // maybe it's enough to define values and hardwire them to 0

    /* ASSIGNMENT */
    /* between FFs assignments */
    assign exception1_d = exception0_q;
    assign updiscon1_d = updiscon0_q;
    assign cause1_d = cause0_q;
    assign tval1_d = tval0_q;
    assign qualified1_d = qualified0_q;

    /* FFs inputs */
    assign exception0_d = exception_i;
    assign updiscon0_d = updiscon;
    assign cause0_d = cause_i;
    assign tval0_d = tval_i;
    assign retired_d = retired_i;
    assign final_qualified_d = tc_qualified && ~nc_qualified; // == tc_final_qualified

    /* last cycle */
    assign lc_exception = exception1_q;
    assign lc_updiscon = updiscon1_q;
    assign lc_cause = cause1_q;
    assign lc_tval = tval1_q;
    assign lc_qualified = qualified1_q;
    assign lc_final_qualified = final_qualified_q;

    /* this cycle */
    assign tc_qualified = qualified0_q;
    assign tc_is_branch = is_branch_q;
    assign tc_exception = exception0_q;
    assign tc_retired = retired_q;
    assign tc_first_qualified = !lc_qualified && tc_qualified;
    assign tc_privchange = privchange_q;
    assign tc_context_change = context_change_q; // non mandatory
    //assign tc_precise_context_report = precise_context_report_q; // requires ctype signal CPU side
    //assign tc_context_report_as_disc = context_report_as_disc_q; // ibidem
    //assign tc_no_context_report = no_context_report_q; // ibidem
    //assign tc_imprecise_context_report = imprecise_context_report_q; // ibidem
    assign tc_gt_max_resync = gt_max_resync_q;
    assign tc_et_max_resync = et_max_resync_q;
    assign tc_branch_map_empty = branch_map_empty_q;
    assign tc_branch_map_full = branch_map_full_q;
    //assign tc_branch_misprediction = branch_misprediction_q; // non mandatory
    assign tc_enc_enabled = enc_enabled_q;
    assign tc_enc_disabled = enc_disabled_q;
    assign tc_opmode_change = opmode_change_q;
    //assign tc_packets_lost = packets_lost_q; // non mandatory
    assign tc_cause = cause0_q;
    assign tc_tval = tval0_q;

    /* next cycle */
    assign nc_exception = exception0_d;
    assign nc_privchange = privchange_d;
    //assign nc_precise_context_report = precise_context_report_d; // same as tc version
    //assign nc_context_report_as_disc = context_report_as_disc_d; // same as tc version
    assign nc_branch_map_empty = branch_map_empty_d;
    assign nc_qualified = qualified0_d;
    assign nc_retired = retired_d;

    /* MODULES INSTANTIATION */
    /* REGISTERS */
    trdb_reg i_trdb_reg(
        .clk_i(),
        .rst_ni(rst_ni),

        .trace_activated_o(trace_activated),
        .nocontext_o(nocontext),
        .notime_o(notime),
        .encoder_mode_o(encoder_mode),
        .delta_address_o(delta_address)
    );

    /* FILTER */
    trdb_filter i_trdb_filter(
        .trace_activated_i(trace_activated),
        .trigger_trace_on_i(trigger_trace_on),
        .trigger_trace_off_i(trigger_trace_off),

        .trace_req_deactivate_o(trace_req_deactivate),
        .trace_qualified_o(qualified0_d)
    );

    /* PRIORITY */
    trdb_priority i_trdb_priority(
        .clk_i(),
        .rst_ni(rst_ni),
        .valid_i(),
        .lc_exception_i(lc_exception),
        .lc_updiscon_i(lc_updiscon),
        .tc_qualified_i(tc_qualified),
        .tc_exception_i(tc_exception),
        .tc_retired_i(tc_retired),
        .tc_first_qualified_i(tc_first_qualified),
        .tc_privchange_i(tc_privchange),
        .tc_context_change_i(tc_context_change), // non mandatory
        //.tc_precise_context_report_i(), // requires ctype signal CPU side
        //.tc_context_report_as_disc_i(), // ibidem
        //.tc_imprecise_context_report_i(), // ibidem
        .tc_gt_max_resync_i(tc_gt_max_resync),
        .tc_et_max_resync_i(tc_et_max_resync),
        .tc_branch_map_empty_i(tc_branch_map_empty),
        .tc_branch_map_full_i(tc_branch_map_full),
        //.tc_branch_misprediction_i(), // non mandatory
        //.tc_pbc_i(), // non mandatory
        .tc_enc_enabled_i(tc_enc_enabled),
        .tc_enc_disabled_i(tc_enc_enabled),
        .tc_opmode_change_i(tc_opmode_change),
        .lc_final_qualified_i(lc_final_qualified),
        //.tc_packets_lost_i(), // non mandatory
        .nc_exception_i(nc_exception),
        .nc_privchange_i(nc_privchange),
        .nc_context_change_i(),
        //.nc_precise_context_report_i(), // requires ctype signal CPU side
        //.nc_context_report_as_disc_i(), // ibidem
        .nc_branch_map_empty_i(nc_branch_map_empty),
        .nc_qualified_i(nc_qualified),
        .nc_retired_i(nc_retired),
        //.halted_i(), // non mandatory side band signal
        //.reset_i(), // ibidem
        //.implicit_return_i(), // non mandatory
        //.tc_trigger_req_i(), // non mandatory
        //.notify_o(), // non mandatory, depends on trigger request

        .valid_o(packet_valid),
        .packet_format_o(packet_format),
        .packet_f_sync_subformat_o(packet_f_sync_subformat),
        //.packet_f_opt_ext_subformat_o(), // non mandatory
        .thaddr_o(thaddr),
        .cause_mux_o(cause_mux),
        .tval_mux_o(tval_mux),
        .resync_timer_rst_o(),
        .qual_status_o(qual_status)
    );

    /* BRANCH MAP */
    trdb_branch_map i_trdb_branch_map(
        .clk_i(),
        .rst_ni(rst_ni),
        .valid_i(),
        .branch_taken_i(),
        .flush_i(branch_map_flush),
        //.branch_taken_prediction_i(), // non mandatory

        .map_o(branch_map),
        .branches_o(branch_count),
        //.pbc_o(), // non mandatory - branch prediction mode
        //.misprediction_o(), // non mandatory - ibidem
        .is_full_o(branch_map_full_d),
        .is_empty_o(branch_map_empty_d)
    );

    /* PACKET EMITTER */
    trdb_packet_emitter i_trdb_packet_emitter(
        .clk_i(),
        .rst_ni(),
        .valid_i(),
        .packet_format_i(packet_format),
        .packet_f_sync_subformat_i(packet_f_sync_subformat),
        //.packet_f_opt_ext_subformat_i(), // non mandatory
        .lc_cause_i(lc_cause),
        .lc_tval_i(lc_tval),
        .tc_cause_i(tc_cause),
        .tc_tval_i(tc_tval),
        .nocontext_i(nocontext),
        .notime_i(notime),
        .is_branch_i(),
        .is_branch_taken_i(),
        .priv_i(),
        //.time_i(), // non mandatory
        //.context_i(), // non mandatory
        .iaddr_i(),
        .resync_timeout_i(),
        .cause_mux_i(cause_mux),
        .tval_mux_i(tval_mux),
        .interrupt_i(),
        .thaddr_i(thaddr),
        .tvec_i(),
        .epc_i(),
        .ienable_i(),
        .encoder_mode_i(encoder_mode),
        .qual_status_i(qual_status),
        .delta_address_i(delta_address),
        //.full_address_i(), // non mandatory
        //.implicit_exception_i(), // non mandatory
        //.sijump_i(), // non mandatory
        //.implicit_return_i(), // non mandatory
        //.branch_prediction_i(), // non mandatory
        //.jump_target_cache_i(), // non mandatory
        //.denable_i(), // stand-by
        //.dloss_i(), //stand-by
        //.notify_i(), // non mandatory
        .lc_updiscon_i(lc_updiscon),
        //.irreport_i(), // non mandatory
        //.irdepth_i(), // non mandatory
        .branches_i(branch_count),
        .branch_map_i(branch_map),
        
        .packet_payload_o(),
        .payload_length_o(),
        .packet_valid_o(),
        .branch_map_flush_o(branch_map_flush)
    );

    /* RESYNC COUNTER */
    trdb_resync_counter
        #(  .MODE(),        // can be chosen by the user
            .MAX_VALUE())
    i_trdb_resync_counter(
        .clk_i(),
        .rst_ni(),
        .trace_enabled_i(),
        .packet_emitted_i(),
        .resync_rst_i(),
        .gt_resync_max_o(),
        .et_resync_max_o()
    );

    /* REGISTERS */
    always_ff @( posedge clk_i, negedge rst_ni ) begin : registers
        if(~rst_ni) begin
            exception0_q <= '0;
            exception1_q <= '0;
            updiscon0_q <= '0;
            updiscon1_q <= '0;
            cause0_q <= '0;
            cause1_q <= '0;
            tval0_q <= '0;
            tval1_q <= '0;
            qualified0_q <= '0;
            qualified1_q <= '0;
            is_branch_q <= '0;
            retired_q <= '0;
            privchange_q <= '0;
            context_change_q <= '0;
            //precise_context_report_q <= '0; // requires ctype signal CPU side
            //context_report_as_disc_q <= '0; //ibidem
            //no_context_report_q <= '0; // ibidem
            //imprecise_context_report_q <= '0; // ibidem
            gt_max_resync_q <= '0;
            et_max_resync_q <= '0;
            branch_map_empty_q <= '0;
            branch_map_full_q <= '0;
            //branch_misprediction_q <= '0; // non mandatory
            enc_enabled_q <= '0;
            enc_disabled_q <= '0;
            opmode_change_q <= '0;
            final_qualified_q <= '0;
            //packets_lost_q <= '0; // non mandatory
        end else begin
            exception0_q <= exception0_d;
            exception1_q <= exception1_d;
            updiscon0_q <= updiscon0_d;
            updiscon1_q <= updiscon1_d;
            cause0_q <= cause0_d;
            cause1_q <= cause1_d;
            tval0_q <= tval0_d;
            tval1_q <= tval1_d;
            qualified0_q <= qualified0_d;
            qualified1_q <= qualified1_d;
            is_branch_q <= is_branch_d;
            retired_q <= retired_d;
            privchange_q <= privchange_d;
            context_change_q <= context_change_d;
            //precise_context_report_q <= precise_context_report_d; // requires ctype signal CPU side
            //context_report_as_disc_q <= context_report_as_disc_d; //ibidem
            //no_context_report_q <= no_context_report_d; // ibidem
            //imprecise_context_report_q <= imprecise_context_report_d; // ibidem
            gt_max_resync_q <= gt_max_resync_d;
            et_max_resync_q <= et_max_resync_d;
            branch_map_empty_q <= branch_map_empty_d;
            branch_map_full_q <= branch_map_full_d;
            //branch_misprediction_q <= branch_misprediction_d; // non mandatory
            enc_enabled_q <= enc_enabled_d;
            enc_disabled_q <= enc_disabled_d;
            opmode_change_q <= opmode_change_d;
            final_qualified_q <= final_qualified_d;
            //packets_lost_q <= packets_lost_d; // non mandatory       
        end
    end



    
endmodule