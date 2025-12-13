module ramp_generator #(
  parameter DATA_WIDTH = 16,
  parameter MAX_VALUE = 1000  // Stop after sending this many samples
)(
  input  logic        clk,
  input  logic        rst,
  
  output logic        valid,
  input  logic        ready,
  output logic [DATA_WIDTH - 1:0] data


);
  
  logic [DATA_WIDTH-1:0] counter;
  logic enabled;
 
  
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      counter <= '0;
      enabled <= 1'b1;
      valid   <= 1'b0;
      data    <= '0;  //Initialize data on reset
    end else begin

      // Only drive data when we have a transaction
      if (valid && ready) begin
        // Transaction completed, prepare next value
        if (counter == MAX_VALUE-1) begin
          counter <= '0;  // Wrap around (optional)
          // enabled <= 1'b0;  // Stop after one full ramp (optional)
        end else begin
          counter <= counter + 1;
        end
      end
      
      // Assert valid when we have data to send
      valid <= enabled;
      data <= counter;
    end
  end
endmodule