`timescale 1ns / 1ns

module top(
    input   spi_clk_i,
    input   spi_cs_i,
    input   spi_mosi_i,
    output  spi_miso_o,
    
    output  flash_cs_o,
    output  flash_mosi_o,
    input   flash_miso_i
);

assign flash_cs_o   = spi_cs_i;
assign flash_mosi_o = spi_mosi_i;
assign spi_miso_o   = flash_miso_i;

STARTUPE2 #(
   .PROG_USR        ("FALSE"),     // Activate program event security feature. Requires encrypted bitstreams.
   .SIM_CCLK_FREQ   (10     )      // Set the Configuration Clock Frequency(ns) for simulation.
)
STARTUPE2_inst (
   .CFGCLK      (           ),     // 1-bit output: Configuration main clock output
   .CFGMCLK     (           ),     // 1-bit output: Configuration internal oscillator clock output
   .EOS         (           ),     // 1-bit output: Active high output signal indicating the End Of Startup.
   .PREQ        (           ),     // 1-bit output: PROGRAM request to fabric output
   
   .CLK         (1'b0       ),     // 1-bit input: User start-up clock input
   .GSR         (1'b0       ),     // 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
   .GTS         (1'b0       ),     // 1-bit input: Global 3-state input (GTS cannot be used for the port name)
   .KEYCLEARB   (1'b1       ),     // 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
   .PACK        (1'b0       ),     // 1-bit input: PROGRAM acknowledge input
   
   .USRCCLKO    (spi_clk_i  ),     // 1-bit input: User CCLK input
   .USRCCLKTS   (1'b0       ),     // 1-bit input: User CCLK 3-state enable input
   
   .USRDONEO    (1'b0       ),     // 1-bit input: User DONE pin output control
   .USRDONETS   (1'b1       )      // 1-bit input: User DONE 3-state enable output
);

endmodule

