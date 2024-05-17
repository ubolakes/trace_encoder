// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

package trdb_pkg;
    // TODO: add correct length value
    localparam CAUSE_LEN = 5;
    localparam PRIV_LEN = 2; // depends on CPU implementation
    localparam INST_LEN = 32;
    localparam PTYPE_LEN = 4; // is it F + SF? spec not clear
    localparam P_LEN = 5;
    localparam PAYLOAD_LEN = 256;
    localparam TRIGGER_LEN = 4;
    localparam CTYPE_LEN = 2;
`ifdef TRDB_ARCH64 // 64bit arch specific parameters
    localparam XLEN = 64;
`else // 32bit arch
    localparam XLEN = 32;
`endif
    /* both archs parameters */
    // localparams for resync counter
    localparam CYCLE_MODE = 0;
    localparam PACKET_MODE = 1;
    // localparams for irreport and irdepth
    localparam CALL_COUNTER_SIZE = '0;
    localparam RETURN_STACK_SIZE = '0;
    // localparams for branch map - defined by spec
    localparam BRANCH_MAP_LEN = 31;
    localparam BRANCH_COUNT_LEN = 5;
    // localparam for configuration parameter
    


// packet types
typedef enum logic[1:0] { 
    F_OPT_EXT       = 2'h0,
    F_DIFF_DELTA    = 2'h1,
    F_ADDR_ONLY     = 2'h2,
    F_SYNC          = 2'h3
} trdb_format_e;

// subformats available for type 3 packets (F_SYNC)
typedef enum logic[1:0] { 
    SF_START    = 2'h0,
    SF_TRAP     = 2'h1,
    SF_CONTEXT  = 2'h2,
    SF_SUPPORT  = 2'h3
} trdb_f_sync_subformat_e;

// subformats available for type 0 packets (F_OPT_EXT)
// used a struct for future extensions
typedef enum logic[0:0] {
    SF_PBC = 1'h0, // correctly predicted branches
    SF_JTC = 1'h1 // jump target cache in spec
} trdb_f_opt_ext_subformat_e;

// qual_status values necessary for format 3 subformat 3
// packet payload
typedef enum logic[1:0] {
    NO_CHANGE   = 2'h0,
    ENDED_REP   = 2'h1,
    TRACE_LOST  = 2'h2,
    ENDED_NTR   = 2'h3
} qual_status_e;

// enum that determines the ioptions values for
// format 3 subformat 3 packets
typedef enum logic[2:0] {
    DELTA_ADDRESS       = 3'h0,
    FULL_ADDRESS        = 3'h1,
    IMPLICIT_EXCEPTION  = 3'h2,
    SIJUMP              = 3'h3,
    IMPLICIT_RETURN     = 3'h4,
    BRANCH_PREDICTION   = 3'h5,
    JUMP_TARGET_CACHE   = 3'h6
} ioptions_e; // instruction trace options

/*TODO:
    doptions struct for data tracing
    refer to page 36 of the spec */

/* Mask and match parameter for itype determination */
parameter MASK_BEQ = 32'h707f;
parameter MATCH_BEQ = 32'h63;
parameter MASK_BNE = 32'h707f;
parameter MATCH_BNE = 32'h1063;
parameter MASK_BLT = 32'h707f;
parameter MATCH_BLT = 32'h4063;
parameter MASK_BGE = 32'h707f;
parameter MATCH_BGE = 32'h5063;
parameter MASK_BLTU = 32'h707f;
parameter MATCH_BLTU = 32'h6063;
parameter MASK_BGEU = 32'h707f;
parameter MATCH_BGEU = 32'h7063;
parameter MASK_P_BNEIMM = 32'h707f;
parameter MATCH_P_BNEIMM = 32'h3063;
parameter MASK_P_BEQIMM = 32'h707f;
parameter MATCH_P_BEQIMM = 32'h2063;
parameter MASK_C_BEQZ = 32'he003;
parameter MATCH_C_BEQZ = 32'hc001;
parameter MASK_C_BNEZ = 32'he003;
parameter MATCH_C_BNEZ = 32'he001;
parameter MASK_C_JALR = 32'hf07f;
parameter MATCH_C_JALR = 32'h9002;
parameter MASK_RD = 32'hf80;
parameter MASK_C_JR = 32'hf07f;
parameter MATCH_C_JR = 32'h8002;
parameter MASK_JALR = 32'h707f;
parameter MATCH_JALR = 32'h67;
parameter MASK_MRET = 32'hffffffff;
parameter MATCH_MRET = 32'h30200073;
parameter MASK_SRET = 32'hffffffff;
parameter MATCH_SRET = 32'h10200073;
parameter MASK_URET = 32'hffffffff;
parameter MATCH_URET = 32'h200073;
parameter MASK_RS1 = 32'hf8000;
parameter MASK_IMM = 32'hfff00000;
parameter X_RA = 32'h1;
parameter OP_SH_RS1 = 32'd15;
parameter OP_SH_RD = 32'd7;




endpackage