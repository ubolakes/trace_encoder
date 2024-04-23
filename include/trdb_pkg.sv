package trdb_pkg; // cercare in snitch
/*    localparam CAUSELEN = 4;
    localparam TVECLEN = 30;
    localparam PRIVLEN = 2;
    localparam INSTLEN = 31;
    localparam PCLEN = 31;
    localparam PTYPELEN = 4;
    localparam PLEN = 4;
    localparam PAYLOADLEN = 32;*/
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


endpackage