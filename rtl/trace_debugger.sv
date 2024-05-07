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

    /* TO DETERMINE IF I NEED ALL OF THEM
    // general control of this module
    // clock enabled
    logic                       trace_enable;
    logic                       clk_gated;
    // tracing enabled
    logic                       trace_activated; // it's read from registers
    // proper privileges for debugging
    logic                       debug_mode;
    // whether input is good
    logic                       trace_valid;
    // control the streamer unit
    logic                       flush_stream;
    logic                       flush_confirm;
    // control the packet fifo
    logic                       clear_fifo;
    logic                       fifo_overflow;
    // special case to jump over vector table entries (which can't be inferred
    // by inspecting the programs' executable
    logic                       packet_after_exception;
    */


    // we have three phases, called last cycle (lc), this cycle (tc) and next
    // cycle (nc), based on which we make decision whether we need to emit a
    // packet or not.
    /* last cycle signals */
    logic                   lc_exception;
    logic                   lc_updiscon;
    logic [CAUSE_LEN-1:0]   lc_cause;
    logic [TVAL_LEN-1:0]    lc_tval;
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
    logic                   tc_final_instr_traced;
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

    /* SIGNALS RECAP
        - this cycle -> _d and _q
            signal is assigned with _q (or 0_q in case it has a lc version)

        - last cycle -> 0_d, 0_q and 1_d, 1_q
            signal is assigned with 1_q
    */

    /* signals for FFs */
    /* this cycle */
    logic   qualified_d, qualified_q;
    logic   is_branch_d, is_branch_q;
    logic   retired_d, retired_q;
    logic   first_qualified_d, first_qualified_q;
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
    logic   packets_lost_d, packets_lost_q; // non mandatory

    /* last cycle */
    logic                   exception0_d, exception0_q;
    logic                   exception1_d, exception1_q;
    logic                   updiscon0_d, updiscon0_q;
    logic                   updiscon1_d, updiscon1_q;
    logic [CAUSE_LEN-1:0]   cause0_d, cause0_q;
    logic [CAUSE_LEN-1:0]   cause1_d, cause1_q;
    logic [TVAL_LEN-1:0]    tval0_d, tval0_q;
    logic [TVAL_LEN-1:0]    tval1_d, tval1_q;

    // registers to hold input data for a few phases
    /*
    Per gestire i segnali di lc, tc, nc, uso dei segnali
    che rappresentano input e output dei due FFD che si 
    occupano di ritardare il segnale.
            ___________                    ___________              
    sig0_d--| D     Q |--sig0_q == sig1_d--| D     Q |--sig1_q
      nc    |         |    tc              |         |    lc
            |   FF0   |                    |   FF1   |
            |_________|                    |_________|
    */

    


    /* TODO:
    1. definire i segnali 0_d, 0_q, 1_d, 1_q
    2. ritardarli tramite FFD
    3. fare assign con i segnali lc, tc, nc
    */


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
    assign exception0_d = exception_i;
    assign exception1_d = exception0_q;
    assign updiscon0_d = updiscon;
    assign updiscon1_d = updiscon0_q;
    assign cause0_d = cause_i;
    assign cause1_d = cause0_q;
    assign tval0_d = tval_i;
    assign tval1_d = tval0_q;
    /* last cycle */
    assign lc_exception = exception1_q;
    assign lc_updiscon = updiscon1_q;
    assign lc_cause = cause1_q;
    assign lc_tval = tval1_q;

    /* this cycle */
    assign tc_qualified = qualified_q;
    assign tc_is_branch = is_branch_q;
    assign tc_exception = exception0_q;
    assign tc_retired = retired_q;
    assign tc_first_qualified = first_qualified_q;
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
    assign tc_final_instr_traced = tc_qualified && ~nc_qualified;
    //assign tc_packets_lost = packets_lost_q; // non mandatory
    assign tc_cause = cause0_q;
    assign tc_tval = tval0_q;

    /* next cycle */
    assign nc_exception = exception0_d;
    assign nc_privchange = privchange_d;
    //assign nc_precise_context_report = precise_context_report_d; // same as tc version
    //assign nc_context_report_as_disc = context_report_as_disc_d; // same as tc version
    assign nc_branch_map_empty = branch_map_empty_d;
    assign nc_qualified = qualified_d;
    assign nc_retired = retired_d;

    /* MODULES INSTANTIATION */
    

    /* REGISTERS */

    always_ff @( posedge clk_i, negedge rst_ni ) begin : registers
        if(~rst_ni) begin
            // setting all _q values to 0
        end else begin
            // assigning _d signals to _q ones
        end
    end



    
endmodule