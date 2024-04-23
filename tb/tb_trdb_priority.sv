`timescale 1ns/1ns

module tb_trdb_priority();

    logic clk;
    logic reset;
    
    // declaration of internal signals
    logic valid_i;
    logic lc_exception_i;
    logic lc_updiscon_i;
    logic tc_qualified_i;
    logic tc_exception_i;
    logic tc_retired_i;
    logic tc_first_qualified_i;
    logic tc_privchange_i;
    logic tc_max_resync_i;
    logic tc_branch_map_empty_i;
    logic tc_branch_map_full_i;
    logic tc_enc_enabled_i;
    logic tc_enc_disabled_i;
    logic tc_opmode_change_i;
    logic lc_final_qualified_i;
    logic nc_exception_i;
    logic nc_privchange_i;
    logic nc_context_change_i;
    logic nc_branch_map_empty_i;
    logic nc_qualified_i;
    logic nc_retired_i;

    // outputs
    logic valid_o;
    logic [1:0] format_o;
    logic [1:0] subformat_o;
    logic thaddr_o;
    logic cause_mux_o;
    logic tval_mux_o;
    logic resync_rst_o;

    //testing only output
    logic expected_valid;
    logic [1:0] expected_format;
    logic [1:0] expected_subformat;
    logic expected_thaddr;
    logic expected_cause_mux;
    logic expected_tval_mux;
    logic expected_resync_rst;
    
    // iteration variable
    logic [31:0] i;

    // DUT instantiation
    trdb_priority DUT(
        .clk_i(clk),
        .rst_ni(reset),
        .valid_i(valid_i),
        .lc_exception_i(lc_exception_i),
        .lc_updiscon_i(lc_updiscon_i),
        .tc_qualified_i(tc_qualified_i),
        .tc_exception_i(tc_exception_i),
        .tc_retired_i(tc_retired_i),
        .tc_first_qualified_i(tc_first_qualified_i),
        .tc_privchange_i(tc_privchange_i),
        .tc_max_resync_i(tc_max_resync_i),
        .tc_branch_map_empty_i(tc_branch_map_empty_i),
        .tc_branch_map_full_i(tc_branch_map_full_i),
        .tc_enc_enabled_i(tc_enc_enabled_i),
        .tc_enc_disabled_i(tc_enc_disabled_i),
        .tc_opmode_change_i(tc_opmode_change_i),
        .lc_final_qualified_i(lc_final_qualified_i),
        .nc_exception_i(nc_exception_i),
        .nc_privchange_i(nc_privchange_i),
        .nc_context_change_i(nc_context_change_i),
        .nc_branch_map_empty_i(nc_branch_map_empty_i),
        .nc_qualified_i(nc_qualified_i),
        .nc_retired_i(nc_retired_i),
        .valid_o(valid_o),
        .packet_format_o(format_o),
        .packet_f_sync_subformat_o(subformat_o),
        .thaddr_o(thaddr_o),
        .cause_mux_o(cause_mux_o),
        .tval_mux_o(tval_mux_o),
        .resync_rst_o(resync_rst_o)
    );

    logic [29:0] test_vector[1000:0];
    //     length of line    # of lines
    
    initial // reading test vector
        begin
        $readmemb("testbenchVector", test_vector);
        i = 0;
        reset = 0; // initialization
        end
    
    always @(posedge clk) // on posedge we get expected output
    begin
        {reset, valid_i, lc_exception_i, lc_updiscon_i, tc_qualified_i, tc_exception_i,
        tc_retired_i, tc_first_qualified_i, tc_privchange_i, tc_max_resync_i, tc_branch_map_empty_i,
        tc_branch_map_full_i, tc_enc_enabled_i, tc_enc_disabled_i, tc_opmode_change_i, lc_final_qualified_i,
        nc_exception_i, nc_privchange_i, nc_context_change_i, nc_branch_map_empty_i, nc_qualified_i, nc_retired_i,
        expected_valid, expected_format, expected_subformat, expected_thaddr, expected_cause_mux, expected_tval_mux,
        expected_resync_rst} = test_vector[i]; #10;
    end

    always @(negedge clk) // on negedge we compare the expected result with the actual one
    begin
        // valid_o
        if(expected_valid !== valid_o) begin
            $display("Wrong valid: %b!=%b", expected_valid, valid_o); // printed if it's wrong
        end        
        // format_o
        if(expected_format !== format_o) begin
            $display("Wrong format: %b!=%b", expected_format, format_o);
        end
        // subformat_o
        if(expected_subformat !== subformat_o) begin
            $display("Wrong subformat: %b!=%b", expected_subformat, subformat_o);
        end
        // thaddr_o
        if(expected_thaddr !== thaddr_o) begin
            $display("Wrong thaddr: %b!=%b", expected_thaddr, thaddr_o);
        end
        // cause_mux_o
        if(expected_cause_mux !== cause_mux_o) begin
            $display("Wrong cause_mux: %b!=%b", expected_cause_mux, cause_mux_o);
        end
        // tval_mux_o
        if(expected_tval_mux !== tval_mux_o) begin
            $display("Wrong tval_mux: %b!=%b", expected_tval_mux, tval_mux_o);
        end
        // expected_resync_rst_o
        if(expected_resync_rst !== resync_rst_o) begin
            $display("Wrong resync_rst: %b!=%b", expected_resync_rst, resync_rst_o);
        end    
        
        i = i + 1; // incrementing index
    end

    always
    begin
        clk <= 1; #5;
        clk <= 0; #5;
    end

endmodule