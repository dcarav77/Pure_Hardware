module blinky_lut (
    input  logic        clk,     // 100 MHz, 100 million ticks per second 
    input  logic        rst,     // reset button (center)
    input  logic        btnu,
    input  logic        btnd,
    output logic [15:0] leds,    // all 16 leds
    //output logic        led0
);

    //Up button
    logic btnu_ff1,           //first security guard
          btnu_sync,          //current synchronized button (this clock)
          btnu_sync_d;        //previous synchronized button (last clock)
    
    //Down button
    logic btnd_ff1,         
          btnd_sync,        //Makes the signal perfectly clean and stable
          btnd_sync_d;      //remembers what the button was doing last cycle 

 
                                      //right hand values read first (b4 the clock)
//left hand side update on clock edge
    always_ff @(posedge clk) begin         
        // UP
        btnu_ff1    <= btnu;                
        btnu_sync   <= btnu_ff1;
        btnu_sync_d <= btnu_sync;
        // DOWN
        btnd_ff1    <= btnd;
        btnd_sync   <= btnd_ff1;
        btnd_sync_d <= btnd_sync;  
    end

    // 1-clock pulses
    wire btnu_pulse = btnu_sync & ~btnu_sync_d;
    wire btnd_pulse = btnd_sync & ~btnd_sync_d;  


 
    logic [3:0] speed_index;                    //Speed Index = 0 fastest, 15 slowest                  
    always_ff @(posedge clk) begin
        if (rst) begin
            speed_index <= 4'd3;                 // On reset, start at speed 3 
        
        end else begin
    //When an UP-button pulse arrives, and we're not already at 15, bump speed index up by one 
            if (btnu_pulse && speed_index != 4'd15) speed_index <= speed_index + 1;
    //When a Down-button pulse arrives, and not at 0, bump speed index down by one
            else if (btnd_pulse && speed_index != 4'd0) speed_index <= speed_index - 1;
        end
    end

    // 3) LUT: 
    logic [31:0] target_next; // Speed translator- it converts your button selections (0-15)into counting numbers that make the LED blink at the right speed
 
    // use a reversed index for timing lookup
    wire [3:0] idx_rev = 4'd15 - speed_index;

    always_comb begin           //Speed tranlator
        unique case (idx_rev)               
            4'd0:  target_next = 32'd12_500_000;     // 0.125 s per toggle 8toggles/second
            4'd1:  target_next = 32'd25_000_000;     // 0.25  s
            4'd2:  target_next = 32'd50_000_000;     // 0.5   s
            4'd3:  target_next = 32'd100_000_000;    // 1.0   s
            4'd4:  target_next = 32'd150_000_000;    // 1.5   s
            4'd5:  target_next = 32'd200_000_000;    // 2.0   s
            4'd6:  target_next = 32'd300_000_000;    // 3.0   s
            4'd7:  target_next = 32'd400_000_000;    // 4.0   s
            4'd8:  target_next = 32'd600_000_000;    // 6.0   s
            4'd9:  target_next = 32'd800_000_000;    // 8.0   s
            4'd10: target_next = 32'd1_000_000_000;  // 10.0  s
            4'd11: target_next = 32'd1_200_000_000;  // 12.0  s
            4'd12: target_next = 32'd1_500_000_000;  // 15.0  s
            4'd13: target_next = 32'd2_000_000_000;  // 20.0  s
            4'd14: target_next = 32'd2_500_000_000;  // 25.0  s
            default: target_next = 32'd3_000_000_000; // 30.0 s 
        endcase
    end

    // 4) Glitch-free blinker
    logic [31:0] current_target;               //The route we're driving right now
    logic [31:0] count;                        //How many stops we've completed on current route
    logic        led_q;                        //The actual LED state (on/off)

    always_ff @(posedge clk) begin             //Every time the clock ticks
        if (rst) begin                         //If reset button is pressed
            count          <= 32'd0;           //Start counting from zero
            current_target <= 32'd100_000_000; //Drive the 1-second route 
            led_q          <= 1'b0;            //Turn LED off
        end else begin
            if (count == current_target - 1) begin    //Have we reached the end of our route?
                count          <= 32'd0;              //Yes? Reset stop counter to zero
                led_q          <= ~led_q;             //Toggle LED (on->off, off-> on)
                current_target <= target_next;        //Swich to the newly requested route
            end else begin
                count <= count + 1;
            end
        end
    end

    // 5) Outputs
    //assign led0     = led_q;                          // blinker
    assign leds[0]  = led0;                           // show blinker on LED0
    assign leds[15:1] = (15'h1 << speed_index);       // cursor style
    
    // assign leds[15:1] = (15'h7FFF >> (15 - speed_index)); // bar graph style

endmodule
