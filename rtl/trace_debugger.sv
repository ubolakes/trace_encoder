// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* TOP LEVEL MODULE */

module trace_debugger import trdb_pkg::*;
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
    input logic                     inst_valid_i, // inst_valid_o
    input logic                     iretired_i, // core_events_o.retired_i 
    input logic                     exception_i, // exception
    input logic                     interrupt_i, // cause_irq_q - used with the previous one to discriminate interrupt from exception
    input logic [CAUSE_LEN-1:0]     cause_i, // cause_q
    input logic [TVEC_LEN-1:0]      tvec_i, // tvec_q, contains trap handler address
    input logic [TVAL_LEN-1:0]      tval_i, // not implemented in snitch, mandatory according to the spec
    input logic [PRIV_LEN-1:0]      priv_lvl_i, // priv_lvl_q
    input logic [INST_LEN-1:0]      inst_data_i, // inst_data
    //input logic                     compressed, // to discriminate compressed instructions from the others - in case the CPU supports C extension
    input logic [PC_LEN-1:0]        pc_i, //pc_q - instruction address
    input logic [EPC_LEN-1:0]       epc_i, // epc_q, required for format 3 subformat 1
    //input logic [TRIGGER_LEN-1:0]   trigger_i, // must be supported CPU side
    //input logic [CTYPE_LEN-1:0]     ctype_i, // according to the spec it's 1 or 2 bit wide. Used 2 for future compatibility

    // outputs
    // info needed for the encapsulator
    output logic [PTYPE_LEN-1:0]    packet_type_o,
    output logic [P_LEN-1:0]        packet_length_o, // in bytes
    output logic [PAYLOAD_LEN-1:0]  packet_payload_o

    // TODO: add constants to trdb_pkg file
);

    /* signals for management */
    // registers
    logic                           trace_activated;
    logic                           trace_enable;
    logic                           nocontext;
    logic                           notime;
    logic                           encoder_mode;
    logic                           delta_address;
    // filter
    logic                           trace_valid;
    logic                           trigger_trace_on; // hardwired to 0?
    logic                           trigger_trace_off; // hardwired to 0?
    //logic                           qualified; // is it needed or I can use qualified_d?
    logic                           trace_req_deactivate;
    // priority
    trdb_format_e                   packet_format;
    trdb_f_sync_subformat_e         packet_f_sync_subformat;
    logic                           thaddr;
    logic                           lc_tc_mux;
    qual_status_e                   qual_status;
    logic                           branch_map_flush;
    logic [BRANCH_MAP_LEN-1:0]      branch_map;
    logic [BRANCH_COUNT_LEN-1:0]    branch_count;
    logic                           resync_rst;
    // packet emitter
    logic                           packet_valid;
    // resync counter
    logic                           packet_emitted;
    // hardwired
    logic                           compressed;
    // not classified
    logic                           tc_updiscon;

    // we have three phases, called last cycle (lc), this cycle (tc) and next
    // cycle (nc), based on which we make decision whether we need to emit a
    // packet or not.
    logic                           first_qualified;
    logic                           nc_branch_map_empty;
    logic [PC_LEN-1:0]              nc_iaddr;

    
    /* MANAGING LC, TC, NC SIGNALS */
    /*
    To manage lc, tc, nc signals I decided to use two 
    serially connected FFs.
            ___________                    ___________              
    sig0_d--| D     Q |--sig0_q == sig1_d--| D     Q |--sig1_q
      nc    |         |    tc              |         |    lc
            |   FF0   |                    |   FF1   |
            |_________|                    |_________|
    
    For input signals I need another FF to sample them:
            ___________                    ___________                    ___________
    sig_i --| D     Q |--sig0_q == sig1_d--| D     Q |--sig1_q == sig2_d--| D     Q |--sig2_q
    input   |         |    nc              |         |    tc              |         |    lc
            |   FF0   |                    |   FF1   |                    |   FF2   |
            |_________|                    |_________|                    |_________|
    examples of this are: exception_i
    
    Nonetheless all inputs must be sampled and the output of the FF is considered nc.
    */

    /* signals for FFs */
    //TODO: split signals into: next cycles, this cycle, last cycle
    // inputs - temporary classification
    logic                           inst_valid0_d, inst_valid0_q;
    logic                           inst_valid1_d, inst_valid1_q;
    logic                           iretired0_d, iretired0_q;
    logic                           iretired1_d, iretired1_q;
    logic                           exception0_d, exception0_q;
    logic                           exception1_d, exception1_q;
    logic                           exception2_d, exception2_q;
    logic                           interrupt0_d, interrupt0_q;
    logic                           interrupt1_d, interrupt1_q;
    logic                           interrupt2_d, interrupt2_q;           
    logic [CAUSE_LEN-1:0]           cause0_d, cause0_q;
    logic [CAUSE_LEN-1:0]           cause1_d, cause1_q;
    logic [CAUSE_LEN-1:0]           cause2_d, cause2_q;
    logic [TVEC_LEN-1:0]            tvec0_d, tvec0_q;
    logic [TVEC_LEN-1:0]            tvec1_d, tvec1_q;
    logic [TVAL_LEN-1:0]            tval0_d, tval0_q;
    logic [TVAL_LEN-1:0]            tval1_d, tval1_q;
    logic [TVAL_LEN-1:0]            tval2_d, tval2_q;
    logic [PRIV_LEN-1:0]            priv_lvl0_d, priv_lvl0_q;
    logic [PRIV_LEN-1:0]            priv_lvl1_d, priv_lvl1_q;
    logic [INST_LEN-1:0]            inst_data0_d, inst_data0_q;
    logic [INST_LEN-1:0]            inst_data1_d, inst_data1_q;
    logic [PC_LEN-1:0]              iaddr0_d, iaddr0_q;
    logic [PC_LEN-1:0]              iaddr1_d, iaddr1_q;
    logic [EPC_LEN-1:0]             epc0_d, epc0_q;
    logic [EPC_LEN-1:0]             epc1_d, epc1_q;
    logic [EPC_LEN-1:0]             epc2_d, epc2_q;
    
    /* last cycle - temporary classification*/
    logic                           updiscon0_d, updiscon0_q;
    logic                           updiscon1_d, updiscon1_q;
    logic                           qualified0_d, qualified0_q;
    logic                           qualified1_d, qualified1_q;
    logic                           final_qualified_d, final_qualified_q;

    /* this cycle - temporary classification */
    logic                           privchange_d, privchange_q;
    logic                           context_change_d, context_change_q; // non mandatory
    //logic                           precise_context_report_d, precise_context_report_q; // requires ctype signal CPU side
    //logic                           context_report_as_disc_d, context_report_as_disc_q; // ibidem
    //logic                           no_context_report_d, no_context_report_q; // ibidem
    //logic                           imprecise_context_report_d, imprecise_context_report_q; // ibidem
    logic                           gt_max_resync_d, gt_max_resync_q;
    logic                           et_max_resync_d, et_max_resync_q;
    logic                           branch_map_empty_d, branch_map_empty_q;
    logic                           branch_map_full_d, branch_map_full_q;
    //logic                           branch_misprediction_d, branch_misprediction_q; // non mandatory
    logic                           trace_enable_d, trace_enabled_q;
    logic                           enc_enabled_d, enc_enabled_q;
    logic                           enc_disabled_d, enc_disabled_q;
    //logic                           packets_lost_d, packets_lost_q; // non mandatory
    logic [MODES-1:0]               enc_config_d, enc_config_q;
    logic                           enc_config_change_d, enc_config_change_q;
    logic                           branch_d, branch_q;
    logic                           branch_taken_d, branch_taken_q;

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
    /* hardwired assignments */
    assign encoder_mode = '0;
    assign compressed = '0;
    assign trigger_trace_on = '0;
    assign trigger_trace_off = '0;

    /* between FFs assignments */
    assign inst_valid1_d = inst_valid0_q;
    assign iretired1_d = iretired0_q;
    assign exception1_d = exception0_q;
    assign exception2_d = exception1_q;
    assign interrupt1_d = interrupt0_q;
    assign interrupt2_d = interrupt1_q;
    assign cause1_d = cause0_q;
    assign cause2_d = cause1_q;
    assign tvec1_d = tvec0_q;
    assign tval1_d = tval0_q;
    assign tval2_d = tval1_q;
    assign priv_lvl1_d = priv_lvl0_q;
    assign inst_data1_d = inst_data0_q;
    assign iaddr1_d = iaddr0_q;
    assign epc1_d = epc0_q;
    assign epc2_d = epc1_q;

    assign qualified1_d = qualified0_q;
    assign updiscon1_d = updiscon0_q;

    /* FFs inputs */
    assign inst_valid0_d = inst_valid_i;
    assign iretired0_d = iretired_i;
    assign exception0_d = exception_i;
    assign interrupt0_d = interrupt_i;
    assign cause0_d = cause_i;
    assign tvec0_d = tvec_i;
    assign tval0_d = '0; // not supported by snitch - hardwired to 0 //tval_i;
    assign priv_lvl0_d = priv_lvl_i;
    assign inst_data0_d = inst_data_i;
    assign iaddr0_d = pc_i;
    assign epc0_d = epc_i;

    assign final_qualified_d = qualified0_q && ~qualified0_d; // == tc_final_qualified
    assign privchange_d = (priv_lvl0_q != priv_lvl1_q) && tc_valid;
    assign trace_enable_d = trace_enable;
    assign enc_enabled_d = trace_enable_d && ~trace_enable_q; // == nc_enc_enabled
    assign enc_disabled_d = ~trace_enable_d && trace_enable_q; // == nc_enc_disabled
    assign enc_config_change_d = enc_config_d != enc_config_q; // == nc_enc_config_change

    assign first_qualified = !qualified1_q && qualified0_q; // idea: put it directly in the module port
    assign trace_valid = inst_valid1_q && trace_activated;

    /* next cycle */
    assign nc_iaddr = iaddr0_q; // wait - understand
    assign nc_branch_map_empty = branch_map_empty_d; // wait - understand


    /* MODULES INSTANTIATION */
    /* MAPPED REGISTERS */
    trdb_reg i_trdb_reg(
        .clk_i(),
        .rst_ni(rst_ni),
        .trace_req_off_i(trace_req_deactivate), // from filter
        .trace_req_on_i(trigger_trace_on),      // from trigger unit
        .trace_enable_o(trace_enable),
        .trace_activated_o(trace_activated),
        .nocontext_o(nocontext),
        .notime_o(notime),
        .encoder_mode_o(encoder_mode),
        .delta_address_o(delta_address),
        .configuration_o(enc_config_d)
    );

    /* FILTER */
    trdb_filter i_trdb_filter(
        .trace_enable_i(trace_enable),
        .trigger_trace_off_i(trigger_trace_off),
        .trace_req_deactivate_o(trace_req_deactivate),
        .trace_qualified_o(qualified0_d) // considered nc
    );

    /* PRIORITY */
    // TODO: recheck for correctness
    trdb_priority i_trdb_priority(
        .clk_i(),
        .rst_ni(rst_ni),
        .valid_i(inst_valid1_q),
        .lc_exception_i(exception2_q),
        .lc_updiscon_i(updiscon1_q),
        .tc_qualified_i(qualified0_q),
        .tc_exception_i(exception1_q),
        .tc_retired_i(iretired1_q),
        .tc_first_qualified_i(first_qualified),
        .tc_privchange_i(privchange_q),
        //.tc_context_change_i(), // non mandatory
        //.tc_precise_context_report_i(), // requires ctype signal CPU side
        //.tc_context_report_as_disc_i(), // ibidem
        //.tc_imprecise_context_report_i(), // ibidem
        .tc_gt_max_resync_i(gt_max_resync_q),
        .tc_et_max_resync_i(et_max_resync_q),
        .tc_branch_map_empty_i(branch_map_empty_q),
        .tc_branch_map_full_i(branch_map_full_q),
        //.tc_branch_misprediction_i(), // non mandatory
        //.tc_pbc_i(), // non mandatory
        .tc_enc_enabled_i(enc_enabled_q),
        .tc_enc_disabled_i(enc_disabled_q),
        .tc_opmode_change_i(enc_config_change_q),
        .lc_final_qualified_i(final_qualified_q),
        //.tc_packets_lost_i(), // non mandatory
        .nc_exception_i(exception0_q),
        .nc_privchange_i(privchange_d),
        //.nc_context_change_i(),
        //.nc_precise_context_report_i(), // requires ctype signal CPU side
        //.nc_context_report_as_disc_i(), // ibidem
        .nc_branch_map_empty_i(),
        .nc_qualified_i(qualified0_d),
        .nc_retired_i(iretired0_q),
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
        .lc_tc_mux_o(lc_tc_mux),
        .resync_timer_rst_o(resync_rst),
        .qual_status_o(qual_status)
    );

    /* BRANCH MAP */
    // TODO: recheck for correctness
    trdb_branch_map i_trdb_branch_map(
        .clk_i(),
        .rst_ni(rst_ni),
        .valid_i(),
        .branch_taken_i(branch_taken_d),
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
    // TODO: recheck for correctness
    trdb_packet_emitter i_trdb_packet_emitter(
        .clk_i(),
        .rst_ni(rst_ni),
        .valid_i(packet_valid),
        .packet_format_i(packet_format),
        .packet_f_sync_subformat_i(packet_f_sync_subformat),
        //.packet_f_opt_ext_subformat_i(), // non mandatory
        .lc_cause_i(cause2_q),
        .lc_tval_i(tval2_q),
        .lc_interrupt_i(interrupt2_q),
        .tc_cause_i(cause1_q),
        .tc_tval_i(tval1_q),
        .tc_interrupt_i(interrupt1_q),
        .nocontext_i(nocontext),
        .notime_i(notime),
        .tc_branch_i(branch_q),         // tc
        .tc_branch_taken_i(branch_taken_q),   // tc
        .priv_i(priv_lvl_q),    // tc -> delay from input
        //.time_i(), // non mandatory
        //.context_i(), // non mandatory
        .iaddr_i(iaddr1_q), // tc -> delay from input
        .lc_tc_mux_i(lc_tc_mux),
        .thaddr_i(thaddr),
        .tvec_i(tvec1_q), // tc -> delay from input
        .lc_epc_i(epc2_q),
        .ienable_i(trace_enable),
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
        .lc_updiscon_i(updiscon1_q),
        //.irreport_i(), // non mandatory
        //.irdepth_i(), // non mandatory
        .branches_i(branch_count),
        .branch_map_i(branch_map),
        .packet_payload_o(packet_payload_o),
        .payload_length_o(packet_length_o),
        .packet_valid_o(packet_emitted),
        .branch_map_flush_o(branch_map_flush)
    );

    /* RESYNC COUNTER */
    // TODO: recheck for correctness
    trdb_resync_counter i_trdb_resync_counter( // for testing we keep the def settings
        .clk_i(),
        .rst_ni(rst_ni),
        .trace_enabled_i(trace_enable),
        .packet_emitted_i(packet_emitted),
        .resync_rst_i(resync_rst),
        .gt_resync_max_o(gt_max_resync_d),
        .et_resync_max_o(et_max_resync_d)
    );

    /* INST TYPE DETECTOR */
    trdb_itype_detector i_trdb_itype_detector(
        .valid_i(),
        .tc_inst_data_i(inst_data0_q),
        .compressed_i(compressed), // not supported on snitch
        .tc_iaddr_i(), // TODO: change
        .nc_iaddr_i(), // TODO: change
        .nc_exception_i(exception0_q),
        .nc_branch_o(branch_d),
        .nc_branch_taken_o(branch_taken_d),
        .nc_updiscon_o(updiscon0_d)
    );


    /* REGISTERS MANAGEMENT */
    // TODO: look at Robert's implementation to better understand
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
            inst_valid_q <= '0;
            retired_q <= '0;
            inst_data_q <= '0;
            tvec0_q <= '0;
            tvec1_q <= '0;
            epc0_q <= '0;
            epc1_q <= '0;
            epc2_q <= '0;
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
            trace_enable_q <= '0;
            enc_enabled_q <= '0;
            enc_disabled_q <= '0;
            final_qualified_q <= '0;
            //packets_lost_q <= '0; // non mandatory
            priv_lvl_q <= '0;
            pc_q <= '0;
            enc_config_q <= '0;
            enc_config_change_q <= '0;
            branch_q <= '0;
            branch_taken_q <= '0;
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
            inst_valid_q <= inst_valid_d;
            retired_q <= retired_d;
            inst_data_q <= inst_data_d;
            tvec0_q <= tvec0_d;
            tvec1_q <= tvec1_d;
            epc0_q <= epc0_d;
            epc1_q <= epc1_d;
            epc2_q <= epc2_d;
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
            trace_enable_q <= trace_enable_d;
            enc_enabled_q <= enc_enabled_d;
            enc_disabled_q <= enc_disabled_d;
            final_qualified_q <= final_qualified_d;
            //packets_lost_q <= packets_lost_d; // non mandatory
            priv_lvl_q <= priv_lvl_d;
            pc_q <= pc_d;
            enc_config_q <= enc_config_d;
            enc_config_change_q <= enc_config_change_d;
            branch_q <= branch_d;
            branch_taken_q <= branch_taken_d;
        end
    end
    
endmodule