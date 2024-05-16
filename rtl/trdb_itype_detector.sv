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
    input logic             valid_i, // TODO: is it really necessary?
    input logic [XLEN-1:0]  nc_inst_data_i,
    input logic             nc_compressed_i,
    input logic [PC_LEN:0]  tc_iaddr_i, // nc
    input logic [PC_LEN:0]  nc_iaddr_i, // before nc - theoretically input 
    //input logic             implicit_return_i, // non mandatory
    input logic             nc_exception_i,

    // outputs
    output logic            nc_branch_o,
    output logic            nc_branch_taken_o,
    output logic            nc_updiscon_o
);

    /*logic is_c_jalr;
    logic is_c_jr;*/ 
    logic nc_is_jump;

    assign nc_branch_o =    ((nc_inst_data_i & MASK_BEQ)      == MATCH_BEQ) ||
                            ((nc_inst_data_i & MASK_BNE)      == MATCH_BNE) ||
                            ((nc_inst_data_i & MASK_BLT)      == MATCH_BLT) ||
                            ((nc_inst_data_i & MASK_BGE)      == MATCH_BGE) ||
                            ((nc_inst_data_i & MASK_BLTU)     == MATCH_BLTU) ||
                            ((nc_inst_data_i & MASK_BGEU)     == MATCH_BGEU) ||
                            ((nc_inst_data_i & MASK_P_BNEIMM) == MATCH_P_BNEIMM) ||
                            ((nc_inst_data_i & MASK_P_BEQIMM) == MATCH_P_BEQIMM) ||
                            ((nc_inst_data_i & MASK_C_BEQZ)   == MATCH_C_BEQZ) ||
                            ((nc_inst_data_i & MASK_C_BNEZ)   == MATCH_C_BNEZ);
    assign nc_branch_taken_o = nc_compressed_i ?    !(tc_iaddr_i + 2 == nc_iaddr_i):
                                                    !(tc_iaddr_i + 4 == nc_iaddr_i);

    // compressed inst - not supported by snitch
    /* c.jalr and c.jr are both decompressed in order to use an uncompressed jalr */
    /*assign is_c_jalr = ((nc_inst_data_i & MASK_C_JALR) == MATCH_C_JALR)
                        && ((nc_inst_data_i & MASK_RD) != 0);
    assign is_c_jr = ((nc_inst_data_i & MASK_C_JR) == MATCH_C_JR)
                      && ((nc_inst_data_i & MASK_RD) != 0);*/
    // non compressed inst
    assign nc_is_jump = ((nc_inst_data_i & MASK_JALR) == MATCH_JALR)/* || is_c_jalr || is_c_jr*/;
    assign nc_updiscon_o = nc_is_jump || nc_exception_i; // || tc_interrupt - not necessary in snitch since it's coupled w/exception
    

endmodule