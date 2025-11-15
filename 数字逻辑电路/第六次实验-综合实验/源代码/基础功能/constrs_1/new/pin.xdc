# Reset Button (S1)
create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports clk]
set_property -dict { PACKAGE_PIN Y18 IOSTANDARD LVCMOS33 } [get_ports clk]

set_property -dict { PACKAGE_PIN R1    IOSTANDARD LVCMOS33 } [get_ports S1]

# S3
set_property -dict { PACKAGE_PIN P5    IOSTANDARD LVCMOS33 } [get_ports S3]

# UART
set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33 } [get_ports uart_rx]
set_property -dict { PACKAGE_PIN V18   IOSTANDARD LVCMOS33 } [get_ports uart_tx]

set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 } [get_ports led_en[7]]
set_property -dict { PACKAGE_PIN A20 IOSTANDARD LVCMOS33 } [get_ports led_en[6]]
set_property -dict { PACKAGE_PIN B20 IOSTANDARD LVCMOS33 } [get_ports led_en[5]]
set_property -dict { PACKAGE_PIN E18 IOSTANDARD LVCMOS33 } [get_ports led_en[4]]
set_property -dict { PACKAGE_PIN F18 IOSTANDARD LVCMOS33 } [get_ports led_en[3]]
set_property -dict { PACKAGE_PIN D19 IOSTANDARD LVCMOS33 } [get_ports led_en[2]]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports led_en[1]]
set_property -dict { PACKAGE_PIN C19 IOSTANDARD LVCMOS33 } [get_ports led_en[0]]

set_property -dict { PACKAGE_PIN F15 IOSTANDARD LVCMOS33 } [get_ports led_cx[7]]
set_property -dict { PACKAGE_PIN F13 IOSTANDARD LVCMOS33 } [get_ports led_cx[6]]
set_property -dict { PACKAGE_PIN F14 IOSTANDARD LVCMOS33 } [get_ports led_cx[5]]
set_property -dict { PACKAGE_PIN F16 IOSTANDARD LVCMOS33 } [get_ports led_cx[4]]
set_property -dict { PACKAGE_PIN E17 IOSTANDARD LVCMOS33 } [get_ports led_cx[3]]
set_property -dict { PACKAGE_PIN C14 IOSTANDARD LVCMOS33 } [get_ports led_cx[2]]
set_property -dict { PACKAGE_PIN C15 IOSTANDARD LVCMOS33 } [get_ports led_cx[1]]
set_property -dict { PACKAGE_PIN E13 IOSTANDARD LVCMOS33 } [get_ports led_cx[0]]