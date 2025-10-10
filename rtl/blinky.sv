module blinky (
    input  wire clk,
    input  wire rst,   // active-high
    output reg  led0
);
    localparam int TOGGLE_CYCLES = 100_000_000 - 1; // 1s @ 100MHz
    reg [26:0] count = 27'd0;
    reg        led_q = 1'b0;

    always @(posedge clk) begin
        if (rst) begin
            count <= '0;
            led_q <= 1'b0;
        end else if (count == TOGGLE_CYCLES) begin
            count <= '0;
            led_q <= ~led_q;
        end else begin
            count <= count + 1;
        end
    end

    assign led0 = led_q;
endmodule
