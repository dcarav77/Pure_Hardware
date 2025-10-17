## clock pin and I/O standard
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
##Define the input clock (10 ns period = 100MHz)
create_clock -name sys_clk -period 10.000 [get_ports {clk}]

##Reset 
set_property PACKAGE_PIN U18 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

##LED0 (U16)
set_property PACKAGE_PIN U16 [get_ports led0]
set_property IOSTANDARD LVCMOS33 [get_ports led0]

#SWITCH
set_property PACKAGE_PIN V17            [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33     [get_ports {sw[0]}]

set_property PACKAGE_PIN V16            [get_ports  {sw[1]}]
set_property IOSTANDARD LVCMOS33     [get_ports {sw[1]}] 

set_property PACKAGE_PIN W16            [get_ports {sw[2]}]
set_property IOSTANDARD LVCMOS33    [get_ports {sw[2]}]

set_property PACKAGE_PIN W17            [get_ports {sw[3]}]
set_property IOSTANDARD LVCMOS33   [get_ports {sw[3]}]

