// Async FIFO
// Write side (fast / ADC clock) – takes samples from ramp_generator (wr_clk)
// Read side  (slow / system/FFT clock) – feeds the consumer (rd_clk)

module async_fifo #(
    parameter DATA_WIDTH = 16,  // How many bits per word ("slices of pizza")
    parameter ADDR_WIDTH = 4    // Depth = 2^ADDR_WIDTH ("pizza boxes" = 16)
)(
    // Write side (fast / ADC)
    input  wire                     wr_clk,
    input  wire                     wr_rst,
    input  wire [DATA_WIDTH-1:0]    wr_data,
    input  wire                     wr_en,
    output wire                     full,

    // Read side (slow / system)
    input  wire                     rd_clk,
    input  wire                     rd_rst,
    output reg [DATA_WIDTH-1:0]     rd_data,
    input  wire                     rd_en,
    output wire                      empty
);

    localparam DEPTH = 1 << ADDR_WIDTH;

    // ----------------------------------------------------------------
    // Storage (dual-port RAM style: write on wr_clk, read on rd_clk)
    // ----------------------------------------------------------------
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // ----------------------------------------------------------------
    // Binary pointers (one extra bit for wrap-around / full detection)
    // ----------------------------------------------------------------
    reg [ADDR_WIDTH:0] wr_ptr_bin;  // write pointer (binary)
    reg [ADDR_WIDTH:0] rd_ptr_bin;  // read pointer  (binary)

    // Gray-coded pointers
    reg [ADDR_WIDTH:0] wr_ptr_gray;
    reg [ADDR_WIDTH:0] rd_ptr_gray;

    // Synchronized Gray pointers (across clock domains)
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync1_w, rd_ptr_gray_sync2_w;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync1_r, wr_ptr_gray_sync2_r;

    // "Next" pointer values for full/empty computation
    wire [ADDR_WIDTH:0] wr_ptr_bin_next;
    wire [ADDR_WIDTH:0] wr_ptr_gray_next;
    wire [ADDR_WIDTH:0] rd_ptr_bin_next;
    wire [ADDR_WIDTH:0] rd_ptr_gray_next;

    // ----------------------------------------------------------------
    // Combinational "next" pointer calculations
    // ----------------------------------------------------------------
    // Only advance if enabled & not full/empty (actual increment happens in always block)
    assign wr_ptr_bin_next  = wr_ptr_bin + ( (wr_en && !full)  ? 1'b1 : 1'b0 );
    assign wr_ptr_gray_next = wr_ptr_bin_next ^ (wr_ptr_bin_next >> 1);

    assign rd_ptr_bin_next  = rd_ptr_bin + ( (rd_en && !empty) ? 1'b1 : 1'b0 );
    assign rd_ptr_gray_next = rd_ptr_bin_next ^ (rd_ptr_bin_next >> 1);

    // ----------------------------------------------------------------
    // Write side (fast / ADC clock domain)
    // ----------------------------------------------------------------
    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            wr_ptr_bin  <= 0;
            wr_ptr_gray <= 0;
        end 
        else begin
            // Write to memory only when wr_en and not full
            if (wr_en && !full) begin
                mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
                wr_ptr_bin  <= wr_ptr_bin_next;
                wr_ptr_gray <= wr_ptr_gray_next;
            end
        end
    end

    // ----------------------------------------------------------------
    // Read side (slow / system / FFT clock domain)
    // ----------------------------------------------------------------
    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            rd_ptr_bin  <= 0;
            rd_ptr_gray <= 0;
            rd_data     <= 0;
        end 
        else begin
            // Read from memory only when rd_en and not empty
            if (rd_en && !empty) begin
                rd_data     <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
                rd_ptr_bin  <= rd_ptr_bin_next;
                rd_ptr_gray <= rd_ptr_gray_next;
            end
        end
    end

    // ----------------------------------------------------------------
    // Pointer synchronization (2-FF chains)
    // ----------------------------------------------------------------

    // Synchronize READ pointer (Gray) into WRITE clock domain
    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            rd_ptr_gray_sync1_w <= 0;
            rd_ptr_gray_sync2_w <= 0;
        end 
        else begin
            rd_ptr_gray_sync1_w <= rd_ptr_gray;
            rd_ptr_gray_sync2_w <= rd_ptr_gray_sync1_w;
        end
    end

    // Synchronize WRITE pointer (Gray) into READ clock domain
    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            wr_ptr_gray_sync1_r <= 0;
            wr_ptr_gray_sync2_r <= 0;
        end 
        else begin
            wr_ptr_gray_sync1_r <= wr_ptr_gray;
            wr_ptr_gray_sync2_r <= wr_ptr_gray_sync1_r;
        end
    end

    // ----------------------------------------------------------------
    // Full / Empty flag logic (in their respective domains)
    // ----------------------------------------------------------------

    // EMPTY (READ domain):
    //  FIFO is empty when read pointer == synchronized write pointer
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync2_r);

    // FULL (WRITE domain):
    //  FIFO is full when NEXT write pointer == read pointer with MSB inverted.
    assign full = (wr_ptr_gray_next == 
                   {~rd_ptr_gray_sync2_w[ADDR_WIDTH],
                     rd_ptr_gray_sync2_w[ADDR_WIDTH-1:0]});

endmodule