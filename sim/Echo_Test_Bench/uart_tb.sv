//TOP LEVEL TESTBENCH
//Top level = the highest module that has no ports and is the starting point of your simulation.

`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::**;


// ============================================================
// TOP LEVEL TESTBENCH
// ============================================================
module top_tb;

// ----------------------------------------------------------
// 1. Declare a clock
// ----------------------------------------------------------
  logic clk;

// ----------------------------------------------------------
// 2. Instantiate your interface
// ----------------------------------------------------------
    my_interface mif (clk);
  
// ----------------------------------------------------------
// 3. Instantiate your DUT and connect it to interface signals
// ----------------------------------------------------------
    uart_echo dut (
        .clk        (clk),          //DUT clk = tb clock
        .rst        (rst),          //DUT reset from interface
        .uart_tx    (mif.uart_tx),  //DUT uart tx goes into interface 
        .uart_rx    (mif.uart_rx),  //DUT uart rx goes from interface
        .seg        (mif.seg),      //7 seg
        .an         (mif.an),
        .led        (mif.led)        
    );


// ----------------------------------------------------------
// 4. Create a clock (100 MHz = period 10ns)
// ----------------------------------------------------------
  
    initial begin
       clk = 0;
       forever #5 clk = ~clk;
    end

// ----------------------------------------------------------
// 5. Assert then deassert reset
// ----------------------------------------------------------
    initial begin
        mif.rst = 1'b1;
        repeat (10) @(posedge clk)
        mif.rst = 1'b0;
    end

// ----------------------------------------------------------
// 6. Connect interface to UVM and start test
// ----------------------------------------------------------
    initial begin
        uvm_config_db#(virtual my_interface)::set(
            null,
            "*",
            "vif",
             mif
        );

        run_test("uart_basic_test");
    end

// ----------------------------------------------------------
// 7. Simulation timeout (prevent hanging)
// ----------------------------------------------------------
initial begin
    #1000000;  // 1ms simulation time
    $display("Error: Simulation timeout!");
    $finish;
end


endmodule

// MIF = the actual hardware wires - it's the single physical connection between UVM and the DUT

// VIF = a remote control handle to those wires
// vif = virtual interface pointer

//                UVM WORLD                    HDL WORLD
//============================================================

//  Driver  ---->  vif  ----------------------->  mif  --->  DUT pins
//           (pointer)                   (real wires)
