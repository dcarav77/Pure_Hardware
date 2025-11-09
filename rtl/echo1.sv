module uart_echo (
    input  logic clk,
    input  logic rst, 
    output logic uart_tx,
    input  logic uart_rx,
    output logic [7:0] seg,  // segments a..g (active-low)
    output logic [3:0] an    // digit enables (active -low)
    
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
logic [3:0]  rx_bit_index;   // 0=start confirm, 1..8=data, 9=stop
logic [7:0]  rx_shift;       // working buffer  <-- UNCOMMENTED
logic [7:0]  rx_data;        // committed byte
logic        rx_valid;
logic        rx_busy;

logic [7:0]  rx_last_char;    //NEW

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
    rx_valid <= 1'b0; // 1-cycle strobe

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
              // valid start → go to data cadence
              rx_bit_index <= 4'd1;       // next: data bit 0
              rx_counter   <= BAUD_DIV;   // full-bit timing
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
            // optional: if (rx_sync!=1'b1) framing error handling
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

logic [15:0] seg_refresh_div;  //16 bit register (can count from 0 to 65535)
logic [1:0]  seg_dig_sel;  //each time register overflows we bump (0→1→2→3→0)

always_ff @(posedge clk) begin
    if (rst) begin
        seg_refresh_div <= 16'd0;   //system clock: 100Mhz/ 65535 = 1526 times per second 
        seg_dig_sel     <= 2'd0;
    end else begin
        seg_refresh_div <= seg_refresh_div + 16'd1;
        if (&seg_refresh_div)   
            seg_dig_sel <= seg_dig_sel + 2'd1;
    end
end

// Map A-G to 7-seg (active-low)
always_comb begin  // Combinational = No clock = No memory = instantly react to input
    
    an  = 4'b1110;     x// Only rightmost digit ON
   

    // enable rightmost digit
    an = 4'b1110;

    case (rx_last_char)     //rx_last_char (signal)
    "A": seg = 7'b0001000;
    "B": seg = 7'b1100000;
    "C": seg = 7'b0110001;
    "D": seg = 7'b1000010;
    "E": seg = 7'b0110000;
    "F": seg = 7'b0111000;
    "G": seg = 7'b0000100;
        default: seg = 7'b1111111; //off
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
            tx_busy <= 1'b0; // done
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

endmodule
