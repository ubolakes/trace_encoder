[comment]: <> (Author:  Umberto Laghi)
[comment]: <> (Contact: umberto.laghi@studio.unibo.it)
[comment]: <> (Github:  @ubolakes)

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

## Supported features
| Feature                                       | Implemented           |
| :-------------------------------------------: | :-------------------: |
| **Branch Trace**                              |                       |
| Delta address mode                            | :white_check_mark:    |
| Full address mode                             | :white_check_mark:    |
| Implicit exception mode                       | :x:                   |
| Sequentially inferable jump mode              | :x:                   |
| Implicit return mode                          | :x:                   |
| Branch prediction mode                        | :x:                   |
| Jump target cache mode                        | :x:                   |
| **Instruction Trace Interface**               |                       |
| Single-retirement                             | :white_check_mark:    |
| Multiple-retirement                           | :x:                   |
| Trigger unit                                  | :white_check_mark:    |
| **Data Trace**                                | :x:                   |
| **Instruction Trace Encoder Output Packets**  |                       |
| Time                                          | :x:                   |
| Context                                       | :x:                   |

## Testing progress
trace_debugger      :x:  
trdb_branch_map     :white_check_mark:  
trdb_filter         :x:  
trdb_itype_detector :white_check_mark: (no compressed instructions)  
trdb_lzc            :x:  
trdb_packet_emitter :x:  
trdb_priority       :white_check_mark:  
trdb_reg            :x:  
trdb_resync_counter :white_check_mark:  
