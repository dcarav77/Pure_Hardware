`timescale 1ns/1ps

module async_fifo_tb;

    // ------------------------------------------------------------
    // Clocks & resets
    // ------------------------------------------------------------
    logic wr_clk, rd_clk;
    logic wr_rst, rd_rst;

    // ------------------------------------------------------------
    // Write interface
    // ------------------------------------------------------------
    logic [15:0] wr_data;
    logic        wr_en;
    logic        full;

    // ------------------------------------------------------------
    // Read interface
    // ------------------------------------------------------------
    logic [15:0] rd_data;
    logic        rd_en;
    logic        empty;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    async_fifo #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(4)
    ) dut (
        .wr_clk (wr_clk),
        .wr_rst (wr_rst),
        .wr_data(wr_data),
        .wr_en  (wr_en),
        .full   (full),

        .rd_clk (rd_clk),
        .rd_rst (rd_rst),
        .rd_data(rd_data),
        .rd_en  (rd_en),
        .empty  (empty)
    );

    // ------------------------------------------------------------
    // Clock generation
    // ------------------------------------------------------------
    // Write clock: 100 MHz (10 ns period)
    initial begin
        wr_clk = 1'b0;
        forever #5 wr_clk = ~wr_clk;
    end

    // Read clock: 62.5 MHz (16 ns period)
    initial begin
        rd_clk = 1'b0;
        forever #8 rd_clk = ~rd_clk;
    end

    // ------------------------------------------------------------
    // SIMPLE SCOREBOARD ("notebook")
    // ------------------------------------------------------------
    logic [15:0] notebook [0:15];  // expected FIFO contents // 16 pages 16 bits
    int write_record = 0;    // Which page to write  NEXT
    int read_record  = 0;    // Which page to read NEXT
    int error_cnt = 0;

    // Record accepted writes (WRITE DOMAIN)
    always @(posedge wr_clk) begin
        if (wr_rst) begin
            write_record <= 0;
    //If write enabled and FIFO has space
        end else if (wr_en && !full) begin
    //Write data onto current page       
            notebook[write_record] <= wr_data;
            $display("A=%0d B=%h", write_record, wr_data);

    // Move bookmark to next page for future writes    
            write_record <= write_record + 1;
        end
    end

    // Check accepted reads (READ DOMAIN)
    always @(posedge rd_clk) begin
        if (rd_rst) begin
            read_record <= 0;
    //If read enabled and FIFO has DATA begin
        end else if (rd_en && !empty) begin
    
    //Compare data read from FIFO against expected data stored in notebook
    //If read data is not exactly the same as notebook this is an error
            if (rd_data !== notebook [read_record]) begin
            
            $display("[%0t] ❌ SB MISMATCH A=%0d  got=0x%h exp=0x%h",
                $time, read_record, rd_data, notebook[read_record]);
            error_cnt <= error_cnt + 1;

    //match found    
        end else begin
            $display("[%0t] ✅ SB MATCH    idx=%0d  data=0x%h",
                $time, read_record, rd_data);
        end
    //Move to the next value, if match or mismatch
            read_record <= read_record + 1;
        end
    end
 

    // ------------------------------------------------------------
    // Stimulus
    // ------------------------------------------------------------
    initial begin
        $display("=== TEST START ===  t=%0t", $time);

        // Init
        wr_rst  = 1'b1;
        rd_rst  = 1'b1;
        wr_data = '0;
        wr_en   = 1'b0;
        rd_en   = 1'b0;

        // Hold reset
        #30;
        wr_rst = 1'b0;
        rd_rst = 1'b0;

        // ---------------- WRITE BURST ----------------stimulus generator
        // Write 0x1234 // 
        @(negedge wr_clk);
        wr_data = 16'h1234; wr_en = 1'b1;
        @(posedge wr_clk);
        @(negedge wr_clk); wr_en = 1'b0;

        // Write 0x0000
        @(negedge wr_clk);
        wr_data = 16'h0000; wr_en = 1'b1;
        @(posedge wr_clk);
        @(negedge wr_clk); wr_en = 1'b0;

        // Write 0x0001
        @(negedge wr_clk);
        wr_data = 16'h0001; wr_en = 1'b1;
        @(posedge wr_clk);
        @(negedge wr_clk); wr_en = 1'b0;

        $display("\n=== AFTER WRITES === t=%0t  full=%b empty=%b",
                 $time, full, empty);

        // Allow CDC sync into read domain
        repeat (3) @(posedge rd_clk);
        wait (empty == 0);

        // ---------------- READ BURST ----------------
        // Read #0
        @(negedge rd_clk); rd_en = 1'b1;
        @(posedge rd_clk);
        @(negedge rd_clk); rd_en = 1'b0;

        // Read #1
        @(negedge rd_clk); rd_en = 1'b1;
        @(posedge rd_clk);
        @(negedge rd_clk); rd_en = 1'b0;

        // Read #2
        @(negedge rd_clk); rd_en = 1'b1;
        @(posedge rd_clk);
        @(negedge rd_clk); rd_en = 1'b0;

        // ---------------- FINAL CHECK ----------------
        #20;
        if (empty && error_cnt == 0)
            $display("\n✅ TEST PASSED (FIFO empty, no SB errors)");
        else
            $display("\n❌ TEST FAILED (empty=%b errors=%0d)",
                     empty, error_cnt);

        #50;
        $finish;
    end

    

endmodule
