# LVDS CLOCK
set_property IOSTANDARD LVDS_25 [get_ports clk_proc_in_p]
set_property DIFF_TERM FALSE [get_ports clk_proc_in_p]
set_property PACKAGE_PIN E19 [get_ports clk_proc_in_p]

set_property IOSTANDARD LVDS_25 [get_ports clk_proc_in_n]
set_property DIFF_TERM FALSE [get_ports clk_proc_in_n]
set_property PACKAGE_PIN D19 [get_ports clk_proc_in_n]