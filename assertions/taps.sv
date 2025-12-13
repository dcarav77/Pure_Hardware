//TAPS is another way of saying coefficients!

module tap_delay_line #(
    parameter TAPS = 4,
    parameter WIDTH = 16
)(
    input  logic             clk,
    input  logic             rst,
    input  logic             valid_in,
    input  logic [WIDTH-1:0] x_in,
    output logic [WIDTH-1:0] x_delay [0:TAPS-1] //index 0 is the newest sample //TAPS-1 is the oldest sample
);

    always_ff @(posedge clk) begin
        if (rst) begin
            // Clear all slots on reset
            for (int i = 0; i < TAPS; i++) begin
                x_delay[i] <= '0;
            end
        end else if (valid_in) begin
            // The Magic Shift Operation
            for (int i = TAPS-1; i > 0; i--) begin
                x_delay[i] <= x_delay[i-1];  // Shift right
            end
            x_delay[0] <= x_in;              // Load new sample
        end
    end

endmodule