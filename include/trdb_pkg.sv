package trdb_pkg;
    localparam CAUSELEN = ;
    localparam TVECLEN = 
    localparam PRIVLEN = 
    localparam INSTLEN = ;
    localparam PCLEN = ;
    localparam PTYPELEN = ;
    localparam PLEN = ;
    localparam PAYLOADLEN = ;
`ifdef TRDB_ARCH64 // 64bit arch specific parameters
    localparam XLEN = 64;
`else // 32bit arch
    localparam XLEN = 32;
`endif // common parameters



// packet types
typedef enum logic[1:0] { 
    F_OPT_EXT       = 2'h0,
    F_DIFF_DELTA    = 2'h1,
    F_ADDR_ONLY     = 2'h2,
    F_SYNC          = 2'h3
} trdb_format_e;

// subformats available for type 3 packets
typedef enum logic[1:0] { 
    SF_START    = 2'h0,
    SF_TRAP     = 2'h1,
    SF_CONTEXT  = 2'h2,
    SF_SUPPORT  = 2'h3
} trdb_subformat_e;




endpackage