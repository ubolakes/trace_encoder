# trace_encoder
Master thesis project: RISC-V spec compliant trace encoder 

## Modules present
trace_debugger      - top level  
trdb_branch_map     - keeps track of branches  
trdb_filter         - turns on/off the tracing  
trdb_itype_detector - determines the type of an instruction  
trdb_lzc            - leading zero counter  
trdb_packet_emitter - populates the packet payload  
trdb_priority       - determines the packet type  
trdb_reg            - configuration registers for the tracer  
trdb_resync_counter - timer to request sync packets  

## Testing progress
trace_debugger      :x:  
trdb_branch_map     :white_check_mark:  
trdb_filter         :x:  
trdb_itype_detector :x:  
trdb_lzc            :x:  
trdb_packet_emitter :x:  
trdb_priority       :white_check_mark: (excluded keep_bits logic)  
trdb_reg            :x:  
trdb_resync_counter :x:  
