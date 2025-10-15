// -----------------------------------------------------------------------------
// Blinky with LUT-based speed selection (SW3..SW0 = 0..15)
// - 100 MHz input clock (Basys-3 W5)
// - BTNC (U18) as active-high reset
// - LED0 (U16) output
// - SW3..SW0 select one of 16 preset toggle intervals (glitch-free update)
// -----------------------------------------------------------------------------
module blinky_lut (
    input  logic        clk,     // 100 MHz
    input  logic        rst,     // active-high (BTNC)
    input  logic [3:0]  sw,      // SW3..SW0 (asynchronous slide switches)
    output logic        led0
);

    // -----------------------------
    // 1) Sycronize the time
    // -----------------------------
    logic [3:0] sw_ff1, sw_ff2;
    always_ff @(posedge clk) begin
        sw_ff1 <= sw;       // 1st bouncer
        sw_ff2 <= sw_ff1;   // 2nd bouncer
    end
    wire [3:0] sw_sync = sw_ff2;


    // --------------------------------------------
    // 2) LUT: map index -> target toggle interval
    //    Values are "cycles at 100 MHz" per toggle
    // --------------------------------------------
    logic [31:0] target_cycles;

    always_comb begin
        unique case (sw_sync)
            4'd0:  target_cycles = 32'd12_500_000;   // 0.125 s
            4'd1:  target_cycles = 32'd25_000_000;   // 0.25  s
            4'd2:  target_cycles = 32'd50_000_000;   // 0.5   s
            4'd3:  target_cycles = 32'd100_000_000;  // 1.0   s
            4'd4:  target_cycles = 32'd150_000_000;  // 1.5   s
            4'd5:  target_cycles = 32'd200_000_000;  // 2.0   s
            4'd6:  target_cycles = 32'd300_000_000;  // 3.0   s
            4'd7:  target_cycles = 32'd400_000_000;  // 4.0   s
            4'd8:  target_cycles = 32'd600_000_000;  // 6.0   s
            4'd9:  target_cycles = 32'd800_000_000;  // 8.0   s
            4'd10: target_cycles = 32'd1_000_000_000;// 10.0  s
            4'd11: target_cycles = 32'd1_200_000_000;// 12.0  s
            4'd12: target_cycles = 32'd1_500_000_000;// 15.0  s
            4'd13: target_cycles = 32'd2_000_000_000;// 20.0  s
            4'd14: target_cycles = 32'd2_500_000_000;// 25.0  s
            default: // 4'd15
                      target_cycles = 32'd3_000_000_000;// 30.0 s
        endcase
    end

    // -------------------------------------------------------------------
    // 3) Glitch-free handoff: latch active_target only at interval end
    // -------------------------------------------------------------------
    logic [31:0] active_target;
    logic [31:0] count;
    logic        led_q;

    always_ff @(posedge clk) begin
        if (rst) begin
            count         <= 32'd0;
            active_target <= 32'd100_000_000; // default (1.0 s) after reset
            led_q         <= 1'b0;            // LED off on reset
        end else begin
            if (count == active_target - 1) begin  //has the timer reached the target time
                
                //when the Timer FINISHES
                count         <= 32'd0;           //reset timer to 0
                led_q         <= ~led_q;          // toggle LED on/off
                active_target <= target_cycles;   // check new speed setting
            
            end else begin
                count <= count + 1; //keep counting up
            end
        end
    end

    assign led0 = led_q;

endmodule
