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
        .wr_clk(clk),
        .wr_rst(wr_rst),
        .wr_data(wr_data),
        .wr_en(wr_en),
        .full(full),
        .rd_clk(clk),
        .rd_rst(rd_rst),
        .rd_data(rd_data),
        .rd_en(rd_en),
        .empty(empty)
    );
    
    // Clock generation (100 MHz)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
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
        
        // Test 1: Basic write/read
        @(posedge clk);
        wr_data = 16'h1234;
        wr_en = 1'b1;
        
        @(posedge clk);
        wr_en = 1'b0;
        
        repeat(2) @(posedge clk);
        
        rd_en = 1'b1;
        @(posedge clk);
        rd_en = 1'b0;
        
        // Check result
        #10;
        $display("Read data: 0x%h", rd_data);
        
        if (rd_data === 16'h1234)
            $display("✅ Test PASSED!");
        else
            $display("❌ Test FAILED!");
        
        #100;
        $finish;
    end

endmodule