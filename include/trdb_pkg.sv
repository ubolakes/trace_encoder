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

// struct necessary to store ioptions values for
// format 3 subformat 3 packets
// they are read from registers
typedef struct packed {
    logic delta_address; // mandatory
    logic full_address; // optional - name according to the spec
    logic implicit_exception; // optional - name according to the spec 
    logic sijump; // optional - name according to the spec
    logic implicit_return; // optional
    logic branch_prediction; // optional
    logic jump_target_cache; // optional
} ioptions; // instruction trace options

/*TODO:
    doptions struct for data tracing
    refer to page 36 of the spec */


endpackage