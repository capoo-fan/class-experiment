set_property -dict {PACKAGE_PIN Y9  IOSTANDARD LVCMOS33} [get_ports en]   

set_property -dict {PACKAGE_PIN W9  IOSTANDARD LVCMOS33} [get_ports mux_sel]  

set_property -dict {PACKAGE_PIN W4  IOSTANDARD LVCMOS33} [get_ports input_a[0]] 
set_property -dict {PACKAGE_PIN R4  IOSTANDARD LVCMOS33} [get_ports input_a[1]] 
set_property -dict {PACKAGE_PIN T4  IOSTANDARD LVCMOS33} [get_ports input_a[2]] 
set_property -dict {PACKAGE_PIN T5 IOSTANDARD LVCMOS33}  [get_ports input_a[3]]

set_property -dict {PACKAGE_PIN U5 IOSTANDARD LVCMOS33} [get_ports input_b[0]] 
set_property -dict {PACKAGE_PIN W6 IOSTANDARD LVCMOS33} [get_ports input_b[1]] 
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports input_b[2]] 
set_property -dict {PACKAGE_PIN U6 IOSTANDARD LVCMOS33} [get_ports input_b[3]] 
 
set_property -dict {PACKAGE_PIN A21 IOSTANDARD LVCMOS33} [get_ports output_c[0]] 
set_property -dict {PACKAGE_PIN E22 IOSTANDARD LVCMOS33} [get_ports output_c[1]] 
set_property -dict {PACKAGE_PIN D22 IOSTANDARD LVCMOS33} [get_ports output_c[2]] 
set_property -dict {PACKAGE_PIN E21 IOSTANDARD LVCMOS33} [get_ports output_c[3]] 