module uart_echo (
    input  logic clk,
    input  logic rst, 
    output logic uart_tx,
    input  logic uart_rx,
    output logic [7:0] seg,  
    output logic [3:0] an,    
    output logic led
    
);

localparam int BAUD_DIV = 868;

// 2-FF sync
(* ASYNC_REG="TRUE" *) logic rx_ff1, rx_sync;
always_ff @(posedge clk) begin
  if (rst) begin
    rx_ff1  <= 1'b1;
    rx_sync <= 1'b1;
  end else begin
    rx_ff1  <= uart_rx;
    rx_sync <= rx_ff1;
  end
end

// RX state & regs
logic [31:0] rx_counter;
logic [3:0]  rx_bit_index;   
logic [7:0]  rx_shift;       
logic [7:0]  rx_data;        
logic        rx_valid;
logic        rx_busy;

logic [7:0]  rx_last_char;    

// TX regs
logic [31:0] tx_counter;
logic [3:0]  tx_bit_index;
logic [7:0]  tx_data;
logic        tx_busy;

// =========================
// RX: IDLE → START → DATA → STOP
// =========================
always_ff @(posedge clk) begin
  if (rst) begin
    rx_counter   <= 32'd0;
    rx_bit_index <= 4'd0;
    rx_shift     <= 8'd0;
    rx_data      <= 8'd0;
    rx_valid     <= 1'b0;
    rx_busy      <= 1'b0;
 
  end else begin
    rx_valid <= 1'b0; 

//ASSERTION!!!! 
    assert (rx_bit_index <= 4'd9) else //treat the condition as “passed” only when it is exactly 1.
        $error ("RX BIT INDEX OUT OF BOUNDS: %0d", rx_bit_index); //If it’s 0, X, or Z, the assertion is considered failed, and the else part runs.

    if (!rx_busy) begin
      // Detect start (LOW), arm half-bit
      if (rx_sync == 1'b0) begin
        rx_busy      <= 1'b1;
        rx_bit_index <= 4'd0;
        rx_counter   <= (BAUD_DIV >> 1); // ~434
      end
    end else begin
      if (rx_counter != 32'd0) begin
        rx_counter <= rx_counter - 32'd1;
      end else begin
        // tick
        case (rx_bit_index)
          // 0: mid-start confirm
          4'd0: begin
            if (rx_sync != 1'b0) begin
              // false start → abort
              rx_busy      <= 1'b0;
              rx_bit_index <= 4'd0;
            end else begin
           
              rx_bit_index <= 4'd1;       
              rx_counter   <= BAUD_DIV;   
            end
          end

          // 1..8: data bits (LSB first)
          4'd1,4'd2,4'd3,4'd4,4'd5,4'd6,4'd7,4'd8: begin
            rx_shift[rx_bit_index-1] <= rx_sync;
            rx_counter               <= BAUD_DIV;
            rx_bit_index             <= rx_bit_index + 4'd1;
          end

          // 9: stop
          4'd9: begin
        
            rx_data  <= rx_shift;   // commit byte
            rx_valid <= 1'b1;
            rx_busy  <= 1'b0;
            rx_bit_index <= 4'd0;
          end

          default: begin
            rx_busy      <= 1'b0;
            rx_bit_index <= 4'd0;
          end
        endcase
      end
    end
  end
end

// =========================
// Last Character Storage
// =========================
always_ff @(posedge clk) begin
    if (rst)
        rx_last_char <= 8'h00;
    else if (rx_valid)
        rx_last_char <= rx_data; 
end

// =========================
// 7-SEGMENT DISPLAY (show last RX char on rightmost digit)
// =========================

logic [15:0] seg_refresh_div;  
logic [1:0]  seg_dig_sel;  

always_ff @(posedge clk) begin
    if (rst) begin
        seg_refresh_div <= 16'd0;   
        seg_dig_sel     <= 2'd0;
    end else begin
        seg_refresh_div <= seg_refresh_div + 16'd1;
        if (&seg_refresh_div)   
            seg_dig_sel <= seg_dig_sel + 2'd1;
    end
end

// Map A-G to 7-seg (active-low)
always_comb begin  // Combinational = No clock = No memory = instantly react to input
    
    an  = 4'b1110;     /
   

    // enable rightmost digit
    an = 4'b1110;

    case (rx_last_char)
        // CORRECT Basys-3 patterns (verified):
        // Format: {DP, G, F, E, D, C, B, A} where 0=ON, 1=OFF
        "A": seg = 8'b0001_0001;  // A - segments: a,b,c,e,f,g
        "B": seg = 8'b1100_0001;  // B - segments: c,d,e,f,g  
        "C": seg = 8'b0110_0011;  // C - segments: a,d,e,f
        "D": seg = 8'b1000_0101;  // D - segments: b,c,d,e,g
        "E": seg = 8'b0110_0001;  // E - segments: a,d,e,f,g
        "F": seg = 8'b0111_0001;  // F - segments: a,e,f,g
        "G": seg = 8'b0000_1001;  // G - segments: a,b,c,d,f
        default: seg = 8'b1111_1111;  // All off
    endcase
end

// =========================
// TX: echo RX bytes
// =========================
always_ff @(posedge clk) begin
  if (rst) begin
    tx_busy      <= 1'b0;
    tx_counter   <= 32'd0;
    tx_bit_index <= 4'd0;
    tx_data      <= 8'd0;
    uart_tx      <= 1'b1;   // idle HIGH
  end else begin
    if (rx_valid && !tx_busy) begin
      // start new frame
      tx_busy      <= 1'b1;
      tx_data      <= rx_data;
      tx_counter   <= 32'd0;
      tx_bit_index <= 4'd0;
      uart_tx      <= 1'b0; // start bit
    end
    else if (tx_busy) begin
      if (tx_counter == BAUD_DIV - 1) begin
        tx_counter <= 32'd0;
        case (tx_bit_index)
          4'd0: uart_tx <= tx_data[0];
          4'd1: uart_tx <= tx_data[1];
          4'd2: uart_tx <= tx_data[2];
          4'd3: uart_tx <= tx_data[3];
          4'd4: uart_tx <= tx_data[4];
          4'd5: uart_tx <= tx_data[5];
          4'd6: uart_tx <= tx_data[6];
          4'd7: uart_tx <= tx_data[7];
          4'd8: begin
            uart_tx <= 1'b1; // stop
            tx_busy <= 1'b0; // doneA
          end
          default: uart_tx <= 1'b1;
        endcase
        tx_bit_index <= tx_bit_index + 4'd1;
      end else begin
        tx_counter <= tx_counter + 32'd1;
      end
    end
  end
end

assign led = rx_busy || rx_valid;

endmodule
