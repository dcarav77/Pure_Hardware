module fifo_practice (
    input logic         clk,           // clock for all pointers & memory
    input logic         rst,           // reset FIFO state: clear pointers, flags
    input logic [7:0]   data_in,       // Data value that the writer wants to store
    input logic         wr_en,         // Request to write "data_in" into FIFO
    input logic         rd_en,         // Request to read next value from FIFO
    
    output logic [7:0]   data_out,     // Value currently available to be read
    output logic         full,         // High when FIFO has NO more room (Stop WRITING)
    output logic         empty,        // High when FIFO has NO more room (Stop READING)          
    output logic         almost_full,   
    output logic         almost_empty           
);
// Internal Signal Declarations
    logic [1:0]     write_pointer;     // 4 deep FIFO = 0-3
    logic [1:0]     read_pointer;
    logic [7:0]     memory [0:3];      // 4-Slots each holds 8 bits (width)
    logic [3:0]     count;             //


    always @(posedge clk) begin
        if (rst) begin
            count                 <= '0;
            write_pointer         <= '0;
            read_pointer          <= '0;
            full                  <= '1;
            empty                 <= '0;
        end else begin
   
    //Simultaneous Read and Write (Highest Priority)    
        if (wr_en && !full && rd_en && !empty) begin //If a write is requested AND the FIFO isn't full AND a read is requested AND the FIFO isn't empty
    //Only a Valid Write
        end else if (wr_en && !full)           begin
    //Only a Valid Read
        end else if (rd_en && !empty)          begin
 
        end 
    end

    end