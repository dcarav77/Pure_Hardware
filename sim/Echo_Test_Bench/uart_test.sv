// UVM TEST COMPONENT - TOP LEVEL
// UVM test class, controls TIME

`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

class uart_basic_test extends uvm_test;             //You’re defining a new UVM test called uart_basic_test.

    `uvm_component_utils(uart_basic_test)           //"Hello UVM, I exist!"

    uart_driver m_drv;                              // This will send bytes to your uart_echo
    
    // -------- Constructor --------//Every UVM component has this pattern 
    
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction


    // -------- Build phase --------
    // Create the driver object here so m_drv is not null in run_phase 
    
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        m_drv = uart_driver::type_id::create("m_drv",this);
        //    if (!uvm_config_db#(virtual my_interface)::get(this, "", "vif", vif)) begin
        // `uvm_fatal("NOVIF", "uart_driver: no virtual interface set for 'vif'")
        //end
    endfunction


    // -------- Run phase --------
    virtual task run_phase (uvm_phase phase);       //Run phase is where time-based behavior happens.
        phase.raise_objection(this);                //Hey UVM, I’m doing stuff now — do NOT stop the simulation


        m_drv.send_byte(8'h41);                   //Send 'A' to UART

        #1000;                                      // Wait to see what happens


        phase.drop_objection(this);                 //okay, we’re done
    endtask
endclass

//With only #1000
//No env
//No driver
//No sequence
//NO scoreboard


//Constructor-
//name = "What's my name?" (e.g., "m_drv")

//parent = "Who's my boss?" (e.g., this, env)

//super.new = "Tell my parent I exist"