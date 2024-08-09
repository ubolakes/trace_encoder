// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* ITYPE DETECTOR */
/*
it produces the type of the instruction and gives other infos about it
*/

import trdb_pkg::*;

module trdb_itype_detector
(
    input logic             clk_i,
    input logic             rst_ni,
    input logic             lc_valid_i,
    input logic             tc_valid_i,
    input logic             nc_valid_i,
    input logic [XLEN-1:0]  lc_iaddr_i,
    input logic [XLEN-1:0]  tc_iaddr_i,
    input logic [XLEN-1:0]  nc_iaddr_i,
    input logic [XLEN-1:0]  tc_inst_data_i,
    input logic             tc_compressed_i,
    input logic             tc_exception_i,
    //input logic             implicit_return_i, // non mandatory
    
    output logic            tc_branch_o,
    output logic            tc_branch_taken_o,
    output logic            tc_updiscon_o 
);
    /*  EXPLANATION:
        This module considers the lc, tc, nc signals and determines
        how many cycles an address remains.
        In case an address remains more cycles, the signal that 
        communicates wether is a branch or not is delayed to be 
        synchronous with the branch_taken signal.
    */

    //logic is_c_jalr;
    //logic is_c_jr;
    logic tc_is_jump;
    logic tc_nc_valid;
    logic one_cycle;
    logic more_cycles;
    logic ready_to_output;
    logic tc_branch_d, tc_branch_q;

    assign tc_nc_valid = tc_valid_i && nc_valid_i;
    assign one_cycle = tc_iaddr_i != nc_iaddr_i && tc_iaddr_i != lc_iaddr_i;
    assign more_cycles = tc_iaddr_i == nc_iaddr_i && tc_iaddr_i != lc_iaddr_i;
    assign ready_to_output = tc_iaddr_i != nc_iaddr_i && tc_iaddr_i == lc_iaddr_i;
    assign tc_branch_d =    (((tc_inst_data_i & MASK_BEQ)      == MATCH_BEQ) ||
                             ((tc_inst_data_i & MASK_BNE)      == MATCH_BNE) ||
                             ((tc_inst_data_i & MASK_BLT)      == MATCH_BLT) ||
                             ((tc_inst_data_i & MASK_BGE)      == MATCH_BGE) ||
                             ((tc_inst_data_i & MASK_BLTU)     == MATCH_BLTU) ||
                             ((tc_inst_data_i & MASK_BGEU)     == MATCH_BGEU) ||
                             ((tc_inst_data_i & MASK_P_BNEIMM) == MATCH_P_BNEIMM) ||
                             ((tc_inst_data_i & MASK_P_BEQIMM) == MATCH_P_BEQIMM) ||
                             ((tc_inst_data_i & MASK_C_BEQZ)   == MATCH_C_BEQZ) ||
                             ((tc_inst_data_i & MASK_C_BNEZ)   == MATCH_C_BNEZ)) && 
                            tc_valid_i;
    assign tc_branch_taken_o = (tc_compressed_i ?
                                !(tc_iaddr_i + 2 == nc_iaddr_i) :
                                !(tc_iaddr_i + 4 == nc_iaddr_i)) &&
                                tc_nc_valid && ready_to_output;
    // compressed inst - not supported by snitch
    /* c.jalr and c.jr are both decompressed in order to use an uncompressed jalr */
    /*assign is_c_jalr = ((nc_inst_data_i & MASK_C_JALR) == MATCH_C_JALR)
                         && ((nc_inst_data_i & MASK_RD) != 0);
    assign is_c_jr = ((nc_inst_data_i & MASK_C_JR) == MATCH_C_JR)
                       && ((nc_inst_data_i & MASK_RD) != 0);*/
    // non compressed inst
    assign tc_is_jump = ((tc_inst_data_i & MASK_JALR) == MATCH_JALR) &&
                        nc_valid_i; /* || is_c_jalr || is_c_jr*/;
    assign tc_updiscon_o = (tc_is_jump || tc_exception_i) &&
                            nc_valid_i; // || nc_interrupt - not necessary in snitch since it's coupled w/exception
    
    always_comb begin
        tc_branch_o = 0;

        if (one_cycle) begin
            tc_branch_o = tc_branch_d;
        end else if (ready_to_output) begin
            tc_branch_o = tc_branch_q;
        end
    end

    always_ff @( posedge clk_i, negedge rst_ni ) begin
        if(~rst_ni) begin
            tc_branch_q <= '0;
        end else if (more_cycles) begin
            tc_branch_q <= tc_branch_d;
        end
    end

endmodule