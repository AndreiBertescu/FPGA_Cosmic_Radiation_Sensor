# FLASH SPI
set_property IOSTANDARD LVTTL [get_ports flash_mosi_o]
set_property PACKAGE_PIN P22 [get_ports flash_mosi_o]

set_property IOSTANDARD LVTTL [get_ports flash_miso_i]
set_property PACKAGE_PIN R22 [get_ports flash_miso_i]

set_property IOSTANDARD LVTTL [get_ports flash_cs_o]
set_property PACKAGE_PIN T19 [get_ports flash_cs_o]


# SD SPI
set_property IOSTANDARD LVTTL [get_ports spi_mosi_i]
set_property PACKAGE_PIN D1 [get_ports spi_mosi_i]

set_property IOSTANDARD LVTTL [get_ports spi_miso_o]
set_property PACKAGE_PIN B1 [get_ports spi_miso_o]

set_property IOSTANDARD LVTTL [get_ports spi_clk_i]
set_property PACKAGE_PIN H3 [get_ports spi_clk_i]

set_property IOSTANDARD LVTTL [get_ports spi_cs_i]
set_property PACKAGE_PIN E1 [get_ports spi_cs_i]


# CONFIGURATION
#set_property CONFIG_MODE SPIx4 [current_design]
#set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
#set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
#set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
#set_property BITSTREAM.GENERAL.PERFRAMECRC YES [current_design]

#set_property BITSTREAM.CONFIG.CONFIGFALLBACK ENABLE [current_design]
#set_property BITSTREAM.CONFIG.NEXT_CONFIG_ADDR 32'h00A00000 [current_design]

# To write a flash config file use:
# 32'h00100000 = 1Mb
# write_cfgmem -format mcs -force -interface SPIX4 -size 64 -loadbit "up 0 C:/Users/andre/IMPORTANT/ICDT/Interface_FlashSPI/Interface_I2C.runs/impl_1/top_golden.bit up 0x0A00000 C:/Users/andre/IMPORTANT/ICDT/Interface_FlashSPI/Interface_I2C.runs/impl_1/top.bit" C:/Users/andre/IMPORTANT/ICDT/Interface_FlashSPI/Interface_I2C.runs/impl_1/flash.mcs


