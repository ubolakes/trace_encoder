/* ITYPE DETECTOR */
/*
it produces the type of the instruction and gives other infos about it
*/

import trdb_pkg::*;

module trdb_itype_detector
(
    input logic             valid_i,
    input logic [XLEN-1:0]  tc_inst_data_i,
    input logic             compressed_i,
    input logic [PC_LEN:0]  tc_iaddr_i,
    input logic [PC_LEN:0]  nc_iaddr_i,
    //input logic             implicit_return_i, // non mandatory

    // outputs
    output logic            is_branch_o,
    output logic            is_branch_taken_o,
    output logic            updiscon_o // it's considered tc, because the inputs are all tc
);
    logic really_c_jr_o;
    logic is_jump_o;
    logic is_priv_ret_o;
    logic not_ret_o;
    logic is_ret_o;
    logic is_c_ret_o;

    always_comb begin: is_branch
        is_branch_o
            = ((tc_inst_data_i & MASK_BEQ)      == MATCH_BEQ) ||
              ((tc_inst_data_i & MASK_BNE)      == MATCH_BNE) ||
              ((tc_inst_data_i & MASK_BLT)      == MATCH_BLT) ||
              ((tc_inst_data_i & MASK_BGE)      == MATCH_BGE) ||
              ((tc_inst_data_i & MASK_BLTU)     == MATCH_BLTU) ||
              ((tc_inst_data_i & MASK_BGEU)     == MATCH_BGEU) ||
              ((tc_inst_data_i & MASK_P_BNEIMM) == MATCH_P_BNEIMM) ||
              ((tc_inst_data_i & MASK_P_BEQIMM) == MATCH_P_BEQIMM) ||
              ((tc_inst_data_i & MASK_C_BEQZ)   == MATCH_C_BEQZ) ||
              ((tc_inst_data_i & MASK_C_BNEZ)   == MATCH_C_BNEZ);
    end

    always_comb begin: is_discontinuity
        really_c_jalr = ((tc_inst_data_i & MASK_C_JALR) == MATCH_C_JALR)
                        && ((tc_inst_data_i & MASK_RD) != 0);

        really_c_jr = ((tc_inst_data_i & MASK_C_JR) == MATCH_C_JR)
                      && ((tc_inst_data_i & MASK_RD) != 0);

        is_jump = ((tc_inst_data_i & MASK_JALR) == MATCH_JALR) ||
                  really_c_jalr || really_c_jr;

        is_priv_ret = ((tc_inst_data_i & MASK_MRET) == MATCH_MRET) ||
                  ((tc_inst_data_i & MASK_SRET) == MATCH_SRET) ||
                  ((tc_inst_data_i & MASK_URET) == MATCH_URET);

        // allows us to mark ret's as not being discontinuities, if we want
        not_ret = '1;
        is_ret = ((tc_inst_data_i & (MASK_JALR | MASK_RD | MASK_RS1 | MASK_IMM)) ==
                 (MATCH_JALR | (X_RA << OP_SH_RS1)));
        is_c_ret = (tc_inst_data_i & (MASK_C_JR | MASK_RD)) ==
                   (MATCH_C_JR | (X_RA << OP_SH_RD));

        // non mandatory mode
        /*if(implicit_return_i)
            not_ret = !(is_ret || is_c_ret);*/

        updiscon_o = (is_jump || is_priv_ret) && not_ret;
    end

    always_comb begin: is_branch_taken
        is_branch_taken_o = compressed_i ?
                          !(tc_iaddr_i + 2 == nc_iaddr_i):
                          !(tc_iaddr_i + 4 == nc_iaddr_i);
    end
    
endmodule