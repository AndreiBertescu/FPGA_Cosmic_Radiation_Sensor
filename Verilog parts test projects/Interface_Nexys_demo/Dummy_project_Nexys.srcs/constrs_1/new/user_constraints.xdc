# Clock
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports sys_clock]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports sys_clock]


# LEDs
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS25} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS25} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS25} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS25} [get_ports {led[3]}]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS25} [get_ports {led[4]}]
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS25} [get_ports {led[5]}]
set_property -dict {PACKAGE_PIN W15 IOSTANDARD LVCMOS25} [get_ports {led[6]}]
set_property -dict {PACKAGE_PIN Y13 IOSTANDARD LVCMOS25} [get_ports {led[7]}]


# Buttons
set_property -dict {PACKAGE_PIN B22 IOSTANDARD LVCMOS12 } [get_ports { btn_c }]; #IO_L20N_T3_16 Sch=btnc
set_property -dict {PACKAGE_PIN C22 IOSTANDARD LVCMOS12 } [get_ports { btn_l }]; #IO_L20P_T3_16 Sch=btnl
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS12 } [get_ports { btn_r }]; #IO_L6P_T0_16 Sch=btnr
set_property -dict {PACKAGE_PIN F15 IOSTANDARD LVCMOS12 } [get_ports { btn_u }]; #IO_0_16 Sch=btnu
set_property -dict {PACKAGE_PIN D22 IOSTANDARD LVCMOS12 } [get_ports { btn_d }]; #IO_L22N_T3_16 Sch=btnd


# Switches
set_property -dict {PACKAGE_PIN E22  IOSTANDARD LVCMOS12 } [get_ports { sw[0] }]; #IO_L22P_T3_16 Sch=sw[0]
set_property -dict {PACKAGE_PIN F21  IOSTANDARD LVCMOS12 } [get_ports { sw[1] }]; #IO_25_16 Sch=sw[1]
set_property -dict {PACKAGE_PIN G21  IOSTANDARD LVCMOS12 } [get_ports { sw[2] }]; #IO_L24P_T3_16 Sch=sw[2]
set_property -dict {PACKAGE_PIN G22  IOSTANDARD LVCMOS12 } [get_ports { sw[3] }]; #IO_L24N_T3_16 Sch=sw[3]
set_property -dict {PACKAGE_PIN H17  IOSTANDARD LVCMOS12 } [get_ports { sw[4] }]; #IO_L6P_T0_15 Sch=sw[4]
set_property -dict {PACKAGE_PIN J16  IOSTANDARD LVCMOS12 } [get_ports { sw[5] }]; #IO_0_15 Sch=sw[5]
set_property -dict {PACKAGE_PIN K13  IOSTANDARD LVCMOS12 } [get_ports { sw[6] }]; #IO_L19P_T3_A22_15 Sch=sw[6]
set_property -dict {PACKAGE_PIN M17  IOSTANDARD LVCMOS12 } [get_ports { sw[7] }]; #IO_25_15 Sch=sw[7]


# UART
set_property PACKAGE_PIN V18 [get_ports rx]
set_property IOSTANDARD LVCMOS33 [get_ports rx]

set_property PACKAGE_PIN AA19 [get_ports tx]
set_property IOSTANDARD LVCMOS33 [get_ports tx]


# I2C
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports scl]
set_property -dict {PACKAGE_PIN V5 IOSTANDARD LVCMOS33} [get_ports sda]
create_generated_clock -name clk_o -source [get_ports sys_clock] -divide_by 1000 [get_nets i2c_block_0/clk_slow]


# Config
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

