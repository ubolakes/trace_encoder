/* ITYPE DETECTOR */
/*
it produces the type of the instruction and gives other infos about it
*/

import trdb_pkg::*;

module trdb_itype_detector
(
    input logic             valid_i,
    input logic [XLEN-1:0]  inst_data_i,
    input logic             compressed_i,
    input logic [PC_LEN:0]  tc_iaddr_i,
    input logic [PC_LEN:0]  nc_iaddr_i,

    // outputs
    output logic            is_branch_o,
    output logic            is_branch_taken_o,
    // not really necessary
    /*output logic really_c_jalr_o,
    output logic really_c_jr_o,
    output logic is_jump_o,
    output logic is_priv_ret_o,
    output logic not_ret_o,
    output logic is_ret_o,
    output logic is_c_ret_o,*/
    output logic            updiscon_o,



);
    logic really_c_jr_o;
    logic is_jump_o;
    logic is_priv_ret_o;
    logic not_ret_o;
    logic is_ret_o;
    logic is_c_ret_o;

    always_comb begin: is_branch
        is_branch_o
            = ((inst_data_i & MASK_BEQ)      == MATCH_BEQ) ||
              ((inst_data_i & MASK_BNE)      == MATCH_BNE) ||
              ((inst_data_i & MASK_BLT)      == MATCH_BLT) ||
              ((inst_data_i & MASK_BGE)      == MATCH_BGE) ||
              ((inst_data_i & MASK_BLTU)     == MATCH_BLTU) ||
              ((inst_data_i & MASK_BGEU)     == MATCH_BGEU) ||
              ((inst_data_i & MASK_P_BNEIMM) == MATCH_P_BNEIMM) ||
              ((inst_data_i & MASK_P_BEQIMM) == MATCH_P_BEQIMM) ||
              ((inst_data_i & MASK_C_BEQZ)   == MATCH_C_BEQZ) ||
              ((inst_data_i & MASK_C_BNEZ)   == MATCH_C_BNEZ);
    end

    always_comb begin: is_discontinuity

        really_c_jalr_o = ((inst_data_i & MASK_C_JALR) == MATCH_C_JALR)
                        && ((inst_data_i & MASK_RD) != 0);

        really_c_jr_o = ((inst_data_i & MASK_C_JR) == MATCH_C_JR)
                      && ((inst_data_i & MASK_RD) != 0);

        is_jump_o = ((inst_data_i & MASK_JALR) == MATCH_JALR) ||
                  really_c_jalr || really_c_jr;

        is_priv_ret_o = ((inst_data_i & MASK_MRET) == MATCH_MRET) ||
                  ((inst_data_i & MASK_SRET) == MATCH_SRET) ||
                  ((inst_data_i & MASK_URET) == MATCH_URET);

        // allows us to mark ret's as not being discontinuities, if we want
        not_ret_o = '1;
        is_ret_o = ((inst_data_i & (MASK_JALR | MASK_RD | MASK_RS1 | MASK_IMM)) ==
                 (MATCH_JALR | (X_RA << OP_SH_RS1)));
        is_c_ret_o = (inst_data_i & (MASK_C_JR | MASK_RD)) ==
                   (MATCH_C_JR | (X_RA << OP_SH_RD));

        // non mandatory mode
        /*if(trace_implicit_ret)
            not_ret = !(is_ret || is_c_ret);*/

        updiscon_o = (is_jump || is_priv_ret) && not_ret;
    end

    always_comb begin: is_branch_taken
        is_branch_taken_o = compressed_i ?
                          !(tc_iaddr_i + 2 == nc_iaddr_i):
                          !(tc_iaddr_i + 4 == nc_iaddr_i);
    end
    
endmodule