//A UVM driver is nothing more than: A SystemVerilog class that wiggles your DUT signals according to your protocol (UART)
//it gets its data from the sequencer.

//The driver's role is to drive data items to the bus following the interface protocol.

class uart_driver extends uvm_driver;
    virtual my_interface vif;      //This connects to your actual UART pins

    `uvm_component_utils(uart_driver) // Let UVM know this class exists so it can be constructed properly
    
  
    localparam int BAUD_DIV = 868 ; //same as uart_echo.sv
    
    //Constructor
    
    function new(string name, uvm_component parent);
        super.new(name, parent); 
        //parent-> which component owns this driver (usually an environment or an agent)
        //name → string name of this instance (e.g., "m_drv").
   
    endfunction


    // SIMPLE METHOD: Send one byte to your UART
    task send_byte(bit [7:0] data);
        `uvm_info("DRIVER", $sformatf("Sending byte: 0x%0h '%0s'", data, data), UVM_LOW)

        int i;

        //1) Make sure line is idle before starting
        vif.uart_rx <= 1'b1;
        #100; // Small delay

        //2) Start Bit (0)
        vif.uart_rx <= 1'b0;
        repeat (BAUD_DIV) @(posedge vif.clk);       // wait

        //3) Data Bits (LSB first)
        for (i = 0; i < 8; i++) begin
            vif.uart_rx <= data[i];                 // Send bit i
            repeat (BAUD_DIV) @(posedge vif.clk);
        end

        //4) Stop Bit (1) -> returns to idle
        vif.uart_rx <= 1'b1;
        repeat (BAUD_DIV) @(posedge vif.clk);

        `uvm_info("DRIVER", "Byte send complete", UVM_LOW) //

    endtask
endclass
    


//The constructor is always named:  function new (....);  

//Constructor name = new

//Class name = uart_driver

//vif = virtual interface

//vif.uart_rx = The RX pin of your uart_echo module 

//setting it to 0 = drive the UART start bit

//vif.uart_rx = 1'b0; Okay DUT, I’m sending a UART frame. Wake up!”

//@vif.cb - wait for one clock tick using the clocking block (cb) inside the inferface (vif)
//@vif.cb - wait for the next posedge clk


