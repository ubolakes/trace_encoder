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
    logic   lc_exception;
    logic   lc_updiscon;
    /* this cycle signals */
    logic   tc_qualified;
    logic   tc_is_branch;
    logic   tc_exception;
    logic   tc_retired;
    logic   tc_first_qualified;
    logic   tc_privchange;
    logic   tc_context_change; // optional
    //logic   tc_precise_context_change; // requires ctype signal CPU side
    //logic   tc_context_report_as_disc; // ibidem
    //logic   tc_no_context_report;      // ibidem
    //logic   tc_imprecise_context_report; // ibidem
    logic   tc_max_resync;
    logic   tc_branch_map_empty;
    logic   tc_branch_map_full;
    //logic   tc_branch_misprediction; // non mandatory
    logic   tc_enc_enabled;
    logic   tc_enc_disabled;
    logic   tc_final_instr_traced;
    //logic   tc_packets_lost; // non mandatory
    /* next cycle signals */
    logic   nc_exception;
    logic   nc_privchange;
    //logic   nc_precise_context_report; // same as tc version
    //logic   nc_context_report_as_disc; // same as tc version
    logic   nc_branch_map_empty;
    logic   nc_qualified;
    logic   nc_retired;

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

    /* TO DO:
    1. definire i segnali 0_d, 0_q, 1_d, 1_q
    2. ritardarli tramite FFD
    3. fare assign con i segnali lc, tc, nc
    */


    /*  following commented section has non mandatory signals
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
            tc_no_context_report
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

    
endmodule