// Interface between UVM and your DUT

interface my_interface (input logic clk);

// Signals connected to your DUT
logic rst;
logic uart_rx;
logic uart_tx;
logic [7:0] seg;
logic [3:0] an;
logic       led;

clocking cb @(posedge clk); //clocking block tells the simulator. 
                            //Testbench drives rst & uart_rx
                            //Testbench reads uart_tx,seg, an, led

    output rst;
    output uart_rx;

//you still need to: Mark the DUT → TB signals as inputs in the clocking block:
//Bundles all DUT pins

    input   uart_tx;  //tell the simulator these are read only
    input   seg;      //read only
    input   an;       //read only
    input   led;
endclocking

endinterface 