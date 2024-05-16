// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

`timescale 1ns/1ns

module tb_trdb_packet_emitter();

    logic clk;
    logic reset;

    // declaration of internal signals
    logic           valid_i;
    logic [1:0]     packet_format_i;
    logic [1:0]     packet_f_sync_subformat_i;
    logic [4:0]     lc_cause_i;
    logic [X:0]     lc_tval_i;
    logic           lc_interrupt_i;
    logic [4:0]     tc_cause_i;
    logic [X:0]     tc_tval_i;
    logic           tc_interrupt_i;
    logic           nocontext_i;
    logic           notime_i;
    logic           tc_branch_i;
    logic           tc_branch_taken_i;
    logic [1:0]     priv_i;
    logic [31:0]    iaddr_i;
    logic           lc_tc_mux_i;
    logic [X:0]     thaddr_i;
    logic [X:0]     tvec_i;
    logic [X:0]     lc_epc_i;
    logic           ienable_i;
    logic           encoder_mode_i;
    logic           qual_status_i;
    logic           delta_address_i;
    logic           lc_updiscon_i;
    logic           branches_i;
    logic           branch_map_i;    

    // outputs
    logic           packet_valid_o;
    logic [:0]      packet_payload_o;
    logic [:0]      payload_length_o;
    logic           branch_map_flush_o;

    // testing only output
    logic           expected_packet_valid_o;
    logic [:0]      expected_packet_payload_o;
    logic [:0]      expected_payload_length_o;
    logic           expected_branch_map_flush_o;

    // iteration variable
    logic [31:0] i;

    // DUT instantiation
    trdb_packet_emitter DUT(
        .clk_i(),
        .rst_ni(),
        .valid_i(),
        .packet_format_i(),
        .packet_f_sync_subformat_i(),
        .lc_cause_i(),
        .lc_tval_i(),
        .lc_interrupt_i(),
        .tc_cause_i(),
        .tc_tval_i(),
        .tc_interrupt_i(),
        .nocontext_i(),
        .notime_i(),
        
    );

    logic [:0] test_vector[1000:0];
    //     length of line    # of lines

    initial // reading test vector
        begin
        $readmemb("<nome_file>", test_vector);
        i = 0;
        reset = 1;  // set == 1 -> no reset each cycle
                    // set == 0 -> reset each cycle
        end








endmodule