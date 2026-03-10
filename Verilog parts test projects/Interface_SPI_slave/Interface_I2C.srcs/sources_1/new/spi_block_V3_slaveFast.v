module spi_block_V3_fast #(
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

reg spi_cs_d;
reg [FRAME_WIDTH-1 : 0] data_shreg;
assign spi_data_o = IS_LSB_FIRST ? data_shreg[0] : data_shreg[FRAME_WIDTH-1];


// Start/stop handling
always @(posedge spi_clk_i or negedge spi_cs_i) begin
    if(reset_i) begin
        spi_cs_d <= #TP 1'b1;
        busy_o <= #TP 1'b0;
    end else begin
        spi_cs_d <= #TP spi_cs_i;
        busy_o <= #TP (~spi_cs_i & spi_cs_d);
    end 
end


// Data shift register
if((SPI_MODE == 0 | SPI_MODE == 3))
    always @(posedge spi_clk_i or posedge reset_i) begin
        if(reset_i)
            data_shreg <= #TP {FRAME_WIDTH{1'b0}};
        else if(busy_o)
            data_shreg <= #TP data_i;
        else
            data_shreg <= #TP IS_LSB_FIRST ? {1'b0, data_shreg[FRAME_WIDTH-1 : 1]} : {data_shreg[FRAME_WIDTH-2 : 0], 1'b0};
    end
else
    always @(negedge spi_clk_i or posedge reset_i) begin
        if(reset_i)
            data_shreg <= #TP {FRAME_WIDTH{1'b0}};
        else if(busy_o)
            data_shreg <= #TP data_i;
        else
            data_shreg <= #TP IS_LSB_FIRST ? {1'b0, data_shreg[FRAME_WIDTH-1 : 1]} : {data_shreg[FRAME_WIDTH-2 : 0], 1'b0};
    end

endmodule
