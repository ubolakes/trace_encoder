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
    input logic [CAUSELEN:0] cause_i, // cause_q
    input logic [TVECLEN:0] tvec_i, // tvec_q, contains trap handler address
    input logic [TVALLEN:0] tval_i, // not implemented in snitch, mandatory according to the spec
    input logic [PRIVLEN:0] priv_lvl_i, // priv_lvl_q
    input logic [INSTLEN:0] inst_data_i, // inst_data
    //input logic compressed, // to discriminate compressed instructions from the others - in case the CPU supports C extension
    input logic [PCLEN:0] pc_i, //pc_q - instruction address
    input logic [:0] epc_i, // epc_q, required for format 3 subformat 1
    input logic [3:0] trigger_i,

    // outputs
    // info needed for the encapsulator
    output logic [PTYPELEN:0]packet_type_o,
    output logic [PLEN:0] packet_length_o, // in bytes
    output logic [PAYLOADLEN:0] packet_payload_o

    // TO-DO: add constants to trdb_pkg file

    // control signals for the module


);
    
endmodule