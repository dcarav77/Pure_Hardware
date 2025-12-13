module req_ack_checker(input logic clk, req, ack);
    

    property p_req_ack;
        @(posedge clk) 
        // When req is high, check that ack is high exactly 2 cycles later
        req |-> ##2 ack;
    endproperty
    
    // Assertion instance
    assert_req_ack: assert property (p_req_ack) 
        else $error("Ack not received 2 cycles after req");
    
endmodule
----------------------------------------------------------
//Named Property

module range_checker(input logic clk, start, done);
    
    property p_start_done;
        @(posedge clk) 
        // When start is high, done must be high within 1-3 cycles
        start |-> ##[1:3] done;
    endproperty


//Assert Named Property
    
    assert_start_done: assert property (p_start_done)
        else $error("Done not received within 1-3 cycles after start");
endmodule

------------------------------------------------------

module remain_stable (input logic clk, valid, ready, input logic [7:0] data);
    
    property p_valid_data;
        @(posedge clk)
        // When valid is high, data should remain stable until ready is high
        (valid && !ready) |-> $stable (data) throughout (valid && !ready);                                   //checking data stability while the receiver is NOT ready.
    endproperty

    assert_valid_data: assert property (p_valid_data_stable)
        else $error ("data did not remain stable");
endmodule


| `##`      | delay in clock cycles |
| `##2`     | wait 2 cycles         |
| `##[1:3]` | wait 1–3 cycles       |

------------------------------------------------------------------------
//Check that rx_valid is a 1-cycle pulse
//In your design, rx_valid is supposed to strobe for exactly one clock cycle when a byte is received.

module joe_rogan (
    input logic clk,
    input logic rst,
    input logic rx_valid
);
    property p_rx_valid_one_cycle;      
        @(posedge clk) disable iff (rst)
//rx_valid is supposed to strobe for exactly one clock cycle when a byte is received.
        rx_valid |-> ##1 !rx_valid;
    endproperty

         assert_p_rx_valid_one_cyle: assert property (p_rx_valid_one_cycle)
        else $error("Done");
endmodule