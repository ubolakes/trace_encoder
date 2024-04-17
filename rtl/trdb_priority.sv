/*PRIORITY*/
/*
change this module name to a more appropriate one
for example "packet identifier" or something similar
*/
/*
it orders packet generation request by priority
*/

import trdb_pkg::*;

module trdb_priority (
    input logic valid_i,

    // refer to page 53 of the specs for clarification

    /*TO DO: determine width of signals, not all are logic*/

    // lc (last cycle) signals
    input logic lc_exception_i, //
    input logic lc_updiscon_i, // updsicon == uninferable PC discontinuity

    // tc (this cycle) signals
    input logic tc_qualified_i, //
    input logic tc_is_branch_i, //
    input logic tc_exception_i,

    //input logic tc_exc_only_i, // not necessary a special input signal
    /* Exc_only meaning:
        Exception or interrupt signalled without
        simultaneous retirement.

        This means that in this cycle only the 
        exception signal is 1 and the number of 
        retired instructions is 0.
    */
    input logic tc_retired_i, // istr retired in tc
    // used to create tc_exc_only and er_n signal


    //input logic tc_reported_i, // what's the meaning? refer to page 51 of spec
    /* Reported meaning:
        The "exception previous" (i.e. the lc_exception)
        was reported in a packet with thaddr = 0 on the
        cycle it occured, beacause it was preceded by an
        updiscon OR immediately followed by another exception
    
        This means I need to consider the value of the previous
        packet and if its thaddr value was 0.
        The thaddr value appears only in 3.1 format packets.
        I need a signal like: "lc_thaddr" (last cycle thaddr),
        the value of this signal is the same as the parameter
        in the packet.    
    
        // ask Simone if the reasoning is correct
    */
    
    //input logic lc_thaddr_i,
    /*  no need to have it as input, because it can be kept as
        a value inside the module*/


    input logic tc_first_qualified_i,
    input logic tc_privchange_i,
    input logic tc_precise_context_change_i,
    input logic tc_context_change_i, // determinable using a comparator with lc_context and tc_context
    input logic tc_context_change_w_discontinuity_i, // understand the meaning
    input logic tc_max_resync_i, // resync timer expired
    input logic tc_branch_map_empty_i,
    
    //input logic tc_er_n_i, // no need for a specific input signal
    /*er_n: exception and retirement in the same cycle*/

    /* rpt_br:  report branches due to full branch_map
                or misprediction    */
    input logic tc_branch_map_full_i,
    input logic tc_branch_misprediction_i, // signal to determine misprediction
    // branch prediction not supported by snitch

    // cci: imprecise context change
    input logic tc_imprecise_context_change_i, // optional
    
    // understand the meaning of branches and pbc in graph at page 53
    /*
    ppccd:  priv has changed OR context has changed
            and it needs to be reported precisely or
            treated as an updiscon
    */

    // format 3 subformat 3 - NOT shown in graph
    input logic tc_enc_enabled_i,
    input logic tc_enc_disabled_i,
    input logic tc_final_instr_traced_i,
    input logic tc_packets_lost_i,


    // nc (next cycle) signals
    input logic nc_exception_i,
    input logic nc_privchange_i,
    input logic nc_precise_context_change_i,
    input logic nc_context_change_w_discontinuity_i,
    input logic nc_branch_map_empty_i,
    input logic nc_qualified_i,

    input logic nc_retired_i, // used w/nc_exception for signal nc_exc_only

    /* 
    ppccd_br:   priv has changed OR context has changed
                and it needs to be reported precisely or
                treated as an updiscon AND branch map is
                not empty
    no need for a dedicated input signal
    Signals required already present
    */


    /* Precise/imprecise context report: refer to page 22 of the spec
        Precise:    required the address of the first instr retired
                    AND the new context.
                    Unreported branches must be reported first.

        Imprecise:  required the new context value
    */

    // trigger input
    input logic [3:0] trigger_i,
    /* if it's value is 4, it's used to request a format 2 packet */

    output logic notify_o,
    // communicates the packet emitter that format 2 packet was requested by trigger unit
    

    output logic            valid_o,
    output trdb_format_e    packet_format_o,
    output trdb_subformat_e packet_subformat_o,
    );

    // refer to question at line 83 of packet_emitter










    // combinatorial network to determine packet format
    always_comb begin : select_packet_format
        // init values
        valid_o = '0;
        packet_format_o = '0;
        packet_subformat_o = '0;
    
        if(valid_i) begin
            if(tc_qualified_i) begin
                if(tc_is_branch_i) begin
                    // update branch map
                end // else: do nothing
                if(lc_exception_i) begin
                    if(/*exception only*/) begin
                        /*
                        format 3 subformat 1
                        thaddr = 0; resync_cnt = 0
                        cause = lc_cause_i; tval = lc_tval
                        */
                    end else begin
                        if (/*reported*/) begin
                            /*
                            format 3 subformat 0
                            resync count = 0
                            */
                        end else begin // not reported
                            /*
                            format 3 subformat 1
                            thaddr = 1 ; resync_cnt = 0
                            */
                        end
                    end
                end else begin
                    if(tc_first_qualified_i || (tc_privchange_i && tc_precise_context_change_i && tc_context_change_w_discontinuity_i) || tc_exception_sync_i) begin
                        /*
                        format 3 subformat 0
                        resync cnt = 0
                        */
                    end else if(lc_updiscon_i) begin
                        if(tc_exception_i) begin
                            /*
                            format 3 subformat 1
                            thaddr = 0 ; resync_cnt = 0
                            tc_cause ; tc_tval
                            */
                        end else begin
                            /*
                            possible formats: 0/1/2
                            to discriminate refer to page 54 of the spec
                            */
                        end
                    end else if(tc_exception_sync_i || /*tc_er_n*/) begin // not lc_updiscon
                        /*
                        possible formats: 0/1/2
                        to discriminate refer to page 54 of the spec
                        */
                    end else if(/*nc except only*/ || (nc_privchange_i && nc_precise_context_change_i && nc_context_change_w_discontinuity_i && ~nc_branch_map_empty_i)) begin
                        /*
                        possible formats: 0/1/2
                        to discriminate refer to page 54 of the spec
                        */
                    end else if(/*rpt_br*/) begin
                        if(/*pbc >= 31*/) begin
                            //format 0 ; no address  
                        end else begin
                            // format 1 ; no address
                        end
                    end else if(tc_imprecise_context_change_i) begin
                        // format 3 subformat 2
                    end /* else begin
                        // no packet
                    end
                        */
                end 
            end
        end
    end


endmodule