# Clock
set_property -dict { PACKAGE_PIN R4    IOSTANDARD LVCMOS33 } [get_ports { sys_clock }]; #IO_L13P_T2_MRCC_34 Sch=sysclk
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports sys_clock]

create_generated_clock -name clk_o -source [get_ports sys_clock] -divide_by 870 [get_nets DUV/baud_clk]

# Button
set_property -dict { PACKAGE_PIN D22 IOSTANDARD LVCMOS12 } [get_ports { reset_i }]; #IO_L22N_T3_16 Sch=btnd

# UART
set_property PACKAGE_PIN V18     [get_ports rx]
set_property IOSTANDARD LVCMOS33 [get_ports rx]

set_property PACKAGE_PIN AA19    [get_ports tx]
set_property IOSTANDARD LVCMOS33 [get_ports tx]