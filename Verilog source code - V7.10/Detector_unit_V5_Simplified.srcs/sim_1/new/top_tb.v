`timescale 1ns / 1ns

module top_tb();

localparam	HALF_100_MHZ_CLOCK_PERIOD =	 5;	//half of the period of the 10 MHz clock
localparam  TP                        =  2;

reg			 clk10;
wire         clk10_p;
wire         clk10_n;

reg      	 spi_cs_i;
reg      	 spi_clk;
wire       	 spi_data_o;
reg       	 spi_data_i;   

// Clock generator
initial begin
	clk10 <= 1'b0;
	forever begin
		#HALF_100_MHZ_CLOCK_PERIOD clk10 <= ~clk10;
	end
end

// SPI clock generator
initial begin
    spi_clk <= #TP 1'b0;
    forever begin
        #(HALF_100_MHZ_CLOCK_PERIOD*100) spi_clk <= #TP ~spi_clk;
    end
end

// Input 10 MHz differential clock signal
assign clk10_p = clk10;
assign clk10_n = ~clk10;


initial begin
    spi_data_i  = 0;
    spi_cs_i    = 1;
    
    #1800000
    spi_cs_i    = 0;
    repeat(81) @(posedge spi_clk);
    spi_cs_i    = 1;
    
    #7000
    spi_cs_i    = 0;
    repeat(81) @(posedge spi_clk);
    spi_cs_i    = 1;
    
    #7000
    spi_cs_i    = 0;
    repeat(81) @(posedge spi_clk);
    spi_cs_i    = 1;
    
    #7000
    spi_cs_i    = 0;
//    repeat(81) @(posedge spi_clk);
//    spi_cs_i    = 1;
end


// DUV
top DUV (
    .clk_proc_in_p  (clk10_p   ),
	.clk_proc_in_n 	(clk10_n   ),
    
    .lvds_spi_io0_p (spi_cs_i	),
    .lvds_spi_io0_n (~spi_cs_i),
    .lvds_spi_io1_p (spi_data_o	),
    .lvds_spi_io1_n (			),
    .lvds_spi_sck_p (spi_clk	),
    .lvds_spi_sck_n (~spi_clk	),
    .lvds_spi_cs_p  (spi_cs_i	),
    .lvds_spi_cs_n  (~spi_cs_i	)
);

endmodule
