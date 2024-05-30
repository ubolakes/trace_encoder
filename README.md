# trace_encoder
Master thesis project: RISC-V spec compliant trace encoder 

## Modules present
trace_debugger      - top level  
trdb_branch_map     - keeps track of branches  
trdb_filter         - turns on/off the tracing__
trdb_itype_detector - determines the type of an instruction__
trdb_lzc            - leading zero counter__
trdb_packet_emitter - populates the packet payload__
trdb_priority       - determines the packet type__
trdb_reg            - configuration registers for the tracer__
trdb_resync_counter - timer to request sync packets__

## Testing progress
trace_debugger      :x:__
trdb_branch_map     :white_check_mark:__
trdb_filter         :x:__
trdb_itype_detector :x:__
trdb_lzc            :x:__
trdb_packet_emitter :x:__
trdb_priority       :white_check_mark: (excluded keep_bits logic)__
trdb_reg            :x:__
trdb_resync_counter :x:__
