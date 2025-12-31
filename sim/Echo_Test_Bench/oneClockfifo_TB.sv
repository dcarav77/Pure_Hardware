// The DIRECTOR
//Not hardware-Exists only in simulation
//Can do “illegal” things on purpose
//What it does: Generates clocks and resets
//Decides when signals change
//Intentionally drives edge cases (good and bad timing)
//

module async_fifo_tb;

    // Clock and reset
    logic clk;
    logic wr_rst, rd_rst;
    
    // Write interface
    logic [15:0] wr_data;
    logic wr_en;
    logic full;
    
    // Read interface  
    logic [15:0] rd_data;
    logic rd_en;
    logic empty;
    
    // Instantiate DUT
    async_fifo #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(4)
    ) dut (
        .wr_clk(clk),           //clock signal same
        .wr_rst(wr_rst),
        .wr_data(wr_data),
        .wr_en(wr_en),
        .full(full),
        .rd_clk(clk),           //clock signal same
        .rd_rst(rd_rst),
        .rd_data(rd_data),
        .rd_en(rd_en),
        .empty(empty)
    );
    
    // Clock generation (100 MHz)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;      // this is only one clock
    end
    
    // Reset and test sequence
    initial begin
        // Initialize
        wr_rst = 1'b1;
        rd_rst = 1'b1;
        wr_data = 16'h0000;
        wr_en = 1'b0;
        rd_en = 1'b0;
        
        // Hold reset
        #30;
        wr_rst = 1'b0;
        rd_rst = 1'b0;
        
       //--- WRITE PHASE --- 
        @(negedge clk);         
        wr_data = 16'h1234;
        wr_en = 1'b1;
        
        @(posedge clk);         // FIFO samples (sees wr_en=1, wr_data=1234)
        @(negedge clk);
        #1;
        wr_en = 1'b0;           // FIFO not allowed to write 

        //Write #0
        @(negedge clk);
        wr_data = 16'h0000;  
        wr_en = 1'b1;
        
        @(posedge clk);
        @(negedge clk);
        #1;                     
        wr_en = 1'b0;            


        //Write #1
        @(negedge clk);
        wr_data = 16'h0001;
        wr_en = 1'b1;
        
        @(posedge clk);
        @(negedge clk);
        #1;
        wr_en = 1'b0;



        $display("\n=== DEBUG AFTER WRITE ===");
        $display("Time: %0t ns", $time);
        $display("full = %b", full);
        $display("empty = %b", empty);
        
        // --- WAIT FOR DATA AVAILABLE ---
        repeat (3) @(posedge clk);
        wait(empty == 0);    // CRITICAL! FIFO needs sync time
        
        
        //--- READ PHASE ---  
        @(negedge clk);
        rd_en = 1'b1;

        @(posedge clk);
        #1;

        if (rd_data === 16'h1234)
            $display("✅ Got 0x1234");
        else
            $display("❌ Expected 0x1234, got 0x%h", rd_data);

        @(negedge clk);
        rd_en = 1'b0; // deassert

        //Read 0
        @(negedge clk);
        rd_en = 1'b1;

        @(posedge clk);
        #1;

        if (rd_data === 16'h0000)
            $display("✅ Got 0x0000");
        else 
            $display("❌ Expected 0x0000, got 0x%h", rd_data);
        
        @(negedge clk);
        rd_en = 1'b0;

        //Read 1
        @(negedge clk);
        rd_en = 1'b1;

        @(posedge clk);
        #1;

        if (rd_data === 16'h0001)
            $display("✅ Got 0x0001");
        else 
            $display("❌ Expected 0x0001, got 0x%h", rd_data);

        @(negedge clk);
        rd_en = 1'b0;

        // Check result
        #10;

        //After last read, FIFO should be empty 
        if (empty === 1'b1)
            $display("✅ Test PASSED! (FIFO empty after reads)");
        else
            $display("❌ Test FAILED! (FIFO not empty)");
        
        #100;
        $finish;
    end

endmodule

