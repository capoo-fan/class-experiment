set_property -dict {PACKAGE_PIN Y18  IOSTANDARD LVCMOS33} [get_ports clk]   

set_property -dict {PACKAGE_PIN R1  IOSTANDARD LVCMOS33} [get_ports rst]  
set_property -dict {PACKAGE_PIN P1  IOSTANDARD LVCMOS33} [get_ports button] 

set_property -dict {PACKAGE_PIN W4  IOSTANDARD LVCMOS33} [get_ports freq_set[0]] 
set_property -dict {PACKAGE_PIN R4  IOSTANDARD LVCMOS33} [get_ports freq_set[1]] 


set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS33}  [get_ports dir_set]

set_property -dict { PACKAGE_PIN F21 IOSTANDARD LVCMOS33 } [get_ports led[7]];
set_property -dict { PACKAGE_PIN G22 IOSTANDARD LVCMOS33 } [get_ports led[6]];
set_property -dict { PACKAGE_PIN G21 IOSTANDARD LVCMOS33 } [get_ports led[5]];
set_property -dict { PACKAGE_PIN D21 IOSTANDARD LVCMOS33 } [get_ports led[4]];
set_property -dict { PACKAGE_PIN E21 IOSTANDARD LVCMOS33 } [get_ports led[3]];
set_property -dict { PACKAGE_PIN D22 IOSTANDARD LVCMOS33 } [get_ports led[2]];
set_property -dict { PACKAGE_PIN E22 IOSTANDARD LVCMOS33 } [get_ports led[1]];
set_property -dict { PACKAGE_PIN A21 IOSTANDARD LVCMOS33 } [get_ports led[0]];

