## ==== Clock (100 MHz) ====
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -name sys_clk -period 10.000 [get_ports clk]

## ==== Buttons ====
set_property PACKAGE_PIN U18 [get_ports rst]   ;# BTNC
set_property PACKAGE_PIN T18 [get_ports btnu]  ;# BTNU
set_property PACKAGE_PIN U17 [get_ports btnd]  ;# BTND
set_property IOSTANDARD LVCMOS33 [get_ports {rst btnu btnd}]

## ==== 16 LEDs (leds[15:0]) ====
set_property PACKAGE_PIN U16 [get_ports {leds[0]}]
set_property PACKAGE_PIN E19 [get_ports {leds[1]}]
set_property PACKAGE_PIN U19 [get_ports {leds[2]}]
set_property PACKAGE_PIN V19 [get_ports {leds[3]}]
set_property PACKAGE_PIN W18 [get_ports {leds[4]}]
set_property PACKAGE_PIN U15 [get_ports {leds[5]}]
set_property PACKAGE_PIN V15 [get_ports {leds[6]}]
set_property PACKAGE_PIN V16 [get_ports {leds[7]}]
set_property PACKAGE_PIN T15 [get_ports {leds[8]}]
set_property PACKAGE_PIN U12 [get_ports {leds[9]}]
set_property PACKAGE_PIN V12 [get_ports {leds[10]}]
set_property PACKAGE_PIN V11 [get_ports {leds[11]}]
set_property PACKAGE_PIN V14 [get_ports {leds[12]}]
set_property PACKAGE_PIN V13 [get_ports {leds[13]}]
set_property PACKAGE_PIN U14 [get_ports {leds[14]}]
set_property PACKAGE_PIN T16 [get_ports {leds[15]}]

# set IO standard for the whole bus in one shot
set_property IOSTANDARD LVCMOS33 [get_ports {leds[*]}]
