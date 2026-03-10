# LVDS CLOCK
set_property IOSTANDARD LVDS_25 [get_ports clk_proc_in_p]
set_property DIFF_TERM FALSE [get_ports clk_proc_in_p]
set_property PACKAGE_PIN E19 [get_ports clk_proc_in_p]

set_property IOSTANDARD LVDS_25 [get_ports clk_proc_in_n]
set_property DIFF_TERM FALSE [get_ports clk_proc_in_n]
set_property PACKAGE_PIN D19 [get_ports clk_proc_in_n]


# SD SPI
#set_property IOSTANDARD LVTTL [get_ports spi_data_i]
#set_property PACKAGE_PIN AA1 [get_ports spi_data_i]

#set_property IOSTANDARD LVTTL [get_ports spi_data_o]
#set_property PACKAGE_PIN AB1 [get_ports spi_data_o]

#set_property IOSTANDARD LVTTL [get_ports spi_clk_i]
#set_property PACKAGE_PIN AB2 [get_ports spi_clk_i]

#set_property IOSTANDARD LVTTL [get_ports spi_cs_i]
#set_property PACKAGE_PIN AB3 [get_ports spi_cs_i]


# LVDS SPI
# MOSI
set_property IOSTANDARD LVDS_25 [get_ports lvds_spi_io0_p]
set_property DIFF_TERM FALSE [get_ports lvds_spi_io0_p]
set_property PACKAGE_PIN B20 [get_ports lvds_spi_io0_p]

set_property IOSTANDARD LVDS_25 [get_ports lvds_spi_io0_n]
set_property DIFF_TERM FALSE [get_ports lvds_spi_io0_n]
set_property PACKAGE_PIN A20 [get_ports lvds_spi_io0_n]

# MISO
set_property IOSTANDARD LVDS_25 [get_ports lvds_spi_io1_p]
set_property DIFF_TERM FALSE [get_ports lvds_spi_io1_p]
set_property PACKAGE_PIN C22 [get_ports lvds_spi_io1_p]

set_property IOSTANDARD LVDS_25 [get_ports lvds_spi_io1_n]
set_property DIFF_TERM FALSE [get_ports lvds_spi_io1_n]
set_property PACKAGE_PIN B22 [get_ports lvds_spi_io1_n]


set_property IOSTANDARD LVDS_25 [get_ports lvds_spi_sck_p]
set_property DIFF_TERM FALSE [get_ports lvds_spi_sck_p]
set_property PACKAGE_PIN B17 [get_ports lvds_spi_sck_p]

set_property IOSTANDARD LVDS_25 [get_ports lvds_spi_sck_n]
set_property DIFF_TERM FALSE [get_ports lvds_spi_sck_n]
set_property PACKAGE_PIN B18 [get_ports lvds_spi_sck_n]


set_property IOSTANDARD LVDS_25 [get_ports lvds_spi_cs_p]
set_property DIFF_TERM FALSE [get_ports lvds_spi_cs_p]
set_property PACKAGE_PIN E22 [get_ports lvds_spi_cs_p]

set_property IOSTANDARD LVDS_25 [get_ports lvds_spi_cs_n]
set_property DIFF_TERM FALSE [get_ports lvds_spi_cs_n]
set_property PACKAGE_PIN D22 [get_ports lvds_spi_cs_n]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGFALLBACK ENABLE [current_design]
set_property BITSTREAM.CONFIG.NEXT_CONFIG_ADDR 32'h00A00000 [current_design]

#write_cfgmem -format mcs -force -interface SPIX4 -size 64 -loadbit "up 0 C:/Users/andre/IMPORTANT/ICDT/Detector_unit_V7.9_Changed_Checksum_16x16/PROGR/top_active.bit up 0x0A00000 C:/Users/andre/IMPORTANT/ICDT/Detector_unit_V7.9_Changed_Checksum_16x16/PROGR/top_passive.bit" C:/Users/andre/IMPORTANT/ICDT/Detector_unit_V7.9_Changed_Checksum_16x16/PROGR/flash.mcs
