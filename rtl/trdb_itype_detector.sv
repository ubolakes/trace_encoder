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
    input logic             tc_exception_i,

    // outputs
    output logic            is_branch_o,
    output logic            is_branch_taken_o,
    output logic            updiscon_o // it's considered tc, because the inputs are all tc
);

    /*logic is_c_jalr;
    logic is_c_jr;*/ 
    logic is_jump;

    assign is_branch_o = ((tc_inst_data_i & MASK_BEQ)      == MATCH_BEQ) ||
                         ((tc_inst_data_i & MASK_BNE)      == MATCH_BNE) ||
                         ((tc_inst_data_i & MASK_BLT)      == MATCH_BLT) ||
                         ((tc_inst_data_i & MASK_BGE)      == MATCH_BGE) ||
                         ((tc_inst_data_i & MASK_BLTU)     == MATCH_BLTU) ||
                         ((tc_inst_data_i & MASK_BGEU)     == MATCH_BGEU) ||
                         ((tc_inst_data_i & MASK_P_BNEIMM) == MATCH_P_BNEIMM) ||
                         ((tc_inst_data_i & MASK_P_BEQIMM) == MATCH_P_BEQIMM) ||
                         ((tc_inst_data_i & MASK_C_BEQZ)   == MATCH_C_BEQZ) ||
                         ((tc_inst_data_i & MASK_C_BNEZ)   == MATCH_C_BNEZ);
    assign is_branch_taken_o = compressed_i ?   !(tc_iaddr_i + 2 == nc_iaddr_i):
                                                !(tc_iaddr_i + 4 == nc_iaddr_i);

    // compressed inst - not supported by snitch
    /*assign is_c_jalr = ((tc_inst_data_i & MASK_C_JALR) == MATCH_C_JALR)
                        && ((tc_inst_data_i & MASK_RD) != 0);
    assign is_c_jr = ((tc_inst_data_i & MASK_C_JR) == MATCH_C_JR)
                      && ((tc_inst_data_i & MASK_RD) != 0);*/
    // non compressed inst    
    assign is_jump = ((tc_inst_data_i & MASK_JALR) == MATCH_JALR)/* || really_c_jalr || really_c_jr*/;
    assign updiscon_o = is_jump || tc_exception_i; // || tc_interrupt - not necessary in snitch since it's coupled w/exception
    

endmodule