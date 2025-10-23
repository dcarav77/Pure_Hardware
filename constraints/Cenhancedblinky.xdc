## ==== Clock (100 MHz) ====
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -name sys_clk -period 10.000 [get_ports clk]

## ==== Buttons ====
# Center reset (BTNC)
set_property PACKAGE_PIN U18 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

# Up button (BTNU)
set_property PACKAGE_PIN T18 [get_ports btnu]
set_property IOSTANDARD LVCMOS33 [get_ports btnu]

# Down button (BTND) 
set_property PACKAGE_PIN U17 [get_ports btnd]
set_property IOSTANDARD LVCMOS33 [get_ports btnd]

## ==== 16 LEDs (leds[15:0]) ====
# LED0 will show the blinking, LEDs 1-15 show speed position
set_property PACKAGE_PIN U16 [get_ports {leds[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[0]}]

set_property PACKAGE_PIN E19 [get_ports {leds[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[1]}]

set_property PACKAGE_PIN U19 [get_ports {leds[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[2]}]

# ... (continue for leds[3] through leds[15] with the correct pins)