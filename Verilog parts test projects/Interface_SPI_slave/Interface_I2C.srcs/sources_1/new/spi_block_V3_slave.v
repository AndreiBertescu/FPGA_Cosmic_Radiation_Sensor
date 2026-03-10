module spi_block_V3 #(
	parameter TP 			= 1,
	parameter FRAME_WIDTH 	= 64,
	parameter SPI_MODE 		= 0,
	parameter IS_LSB_FIRST 	= 1
)(
    input        				reset_i,
    input        				clk_i,
	
	input [FRAME_WIDTH-1 : 0] 	data_i,
	output reg					busy_o,

    input       				spi_cs_i ,
    input       				spi_clk_i ,
    output       				spi_data_o,
    input        				spi_data_i
);

reg 					spi_cs_d;
reg 					spi_clk_d;
wire 					spi_clk;
reg [FRAME_WIDTH-1 : 0] data_shreg;

assign spi_clk = (SPI_MODE == 0 | SPI_MODE == 3) ? (spi_clk_i & ~spi_clk_d) : (~spi_clk_i & spi_clk_d);
assign spi_data_o = IS_LSB_FIRST ? data_shreg[0] : data_shreg[FRAME_WIDTH-1];


// Delay generators
always @(posedge clk_i) begin
	spi_cs_d  <= spi_cs_i;
	spi_clk_d <= spi_clk_i;
end


// Start/stop handling
always @(posedge clk_i or posedge reset_i) begin
	if(reset_i)
		busy_o <= #TP 1'b0;
	else if(~spi_cs_i & spi_cs_d)
		busy_o <= #TP 1'b1;
	else if(spi_cs_i & ~spi_cs_d)
		busy_o <= #TP 1'b0;
end


// Data shift register
always @(posedge clk_i or posedge reset_i) begin
	if(reset_i)
		data_shreg <= #TP {FRAME_WIDTH{1'b0}};
	else if(~spi_cs_i & spi_cs_d)
		data_shreg <= #TP data_i;
	else if(spi_clk)
		data_shreg <= #TP IS_LSB_FIRST ? {1'b0, data_shreg[FRAME_WIDTH-1 : 1]} : {data_shreg[FRAME_WIDTH-2 : 0], 1'b0};
end

endmodule
