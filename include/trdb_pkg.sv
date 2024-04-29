package trdb_pkg; // cercare in snitch
    localparam CAUSE_LEN = 4;
    localparam TVEC_LEN = 29;
    localparam PRIV_LEN = 2;
    localparam INST_LEN = 31;
    localparam PC_LEN = 31;
    localparam PTYPE_LEN = 4;
    localparam P_LEN = 4;
    localparam PAYLOAD_LEN = 31;
`ifdef TRDB_ARCH64 // 64bit arch specific parameters
    localparam XLEN = 64;
`else // 32bit arch
    localparam XLEN = 32;
`endif // common parameters
    
    // parameters for resync counter
    localparam CYCLE_MODE = 0;
    localparam PACKET_MODE = 1;


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
    NO_CHANGE   = 2'h0;
    ENDED_REP   = 2'h1;
    TRACE_LOST  = 2'h2;
    ENDED_NTR   = 2'h3;
} qual_status;

// enum that determines the ioptions values for
// format 3 subformat 3 packets
typedef enum logic[2:0] {
    DELTA_ADDRESS       = 3'h0;
    FULL_ADDRESS        = 3'h1;
    IMPLICIT_EXCEPTION  = 3'h2;
    SIJUMP              = 3'h3;
    IMPLICIT_RETURN     = 3'h4;
    BRANCH_PREDICTION   = 3'h5;
    JUMP_TARGET_CACHE   = 3'h6;
} ioptions; // instruction trace options

/*TODO:
    doptions struct for data tracing
    refer to page 36 of the spec */


endpackage