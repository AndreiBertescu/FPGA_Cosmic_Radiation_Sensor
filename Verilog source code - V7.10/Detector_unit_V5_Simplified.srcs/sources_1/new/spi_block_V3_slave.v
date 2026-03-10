module spi_block_V3 #(
	parameter TP 			= 1,
	parameter FRAME_WIDTH 	= 64,
	parameter SPI_MODE 		= 0,
	parameter IS_LSB_FIRST 	= 1
)(
    input       				clk_iA,
    input       				clk_iB,
    input       				clk_iC,
    input        				reset_i,
	
	input [FRAME_WIDTH-1 : 0] 	data_i,
	output						started_o,
	output						seu_o,

    input       				spi_cs_i ,
    input       				spi_clk_i ,
    output       				spi_data_o,
    input        				spi_data_i
);

reg [3 : 0] 			 spi_cs_d;
reg [3 : 0]				 spi_clk_d;
wire 					 spi_clk;
wire 					 spi_cs;
wire [FRAME_WIDTH-1 : 0] data_shreg;

wire 					 spi_cs_seu;
wire 					 data_shreg_seu;
assign 					 seu_o = spi_cs_seu | data_shreg_seu;

assign spi_clk    = (SPI_MODE == 0 | SPI_MODE == 3) ? (spi_clk_d == 4'b0011) : (spi_clk_d == 4'b1100);
assign spi_data_o = IS_LSB_FIRST ? data_shreg[0] : data_shreg[FRAME_WIDTH-1];
assign started_o  = (spi_cs & spi_clk);


// Delay generators
always @(posedge clk_iA or posedge reset_i) begin
	if(reset_i) begin 
		spi_cs_d  <= 4'b0;
		spi_clk_d <= 4'b0;
	end else begin
		spi_cs_d  <= {spi_cs_d[2:0] , spi_cs_i};
		spi_clk_d <= {spi_clk_d[2:0], spi_clk_i};
	end
end


// Start handling
//always @(posedge clk_i or posedge reset_i) begin
//	if(reset_i)
//		spi_cs <= #TP 1'b0;
//	else if(spi_cs_d == 4'b1100)
//		spi_cs <= #TP 1'b1;
//	else if(spi_cs & spi_clk)
//		spi_cs <= #TP 1'b0;
//end

TMR_register #(
    .SIGNAL_WIDTH(1),
    .RESET_CONDITION_VALUE(1)
) spi_cs_TMR (
    .clk_iA             (clk_iA				),
    .clk_iB             (clk_iB				),
    .clk_iC             (clk_iC				),
    .reset_i            (reset_i			),
    
    .signal_in          (1'b0				),
    .reset_condition_i  (spi_cs_d == 4'b1100),
    .true_condition_i   (spi_cs & spi_clk	),
    
    .signal_out         (spi_cs				),
    .detected_seu_o     (spi_cs_seu			)
);


// Data shift register
//always @(posedge clk_i or posedge reset_i) begin
//	if(reset_i)
//		data_shreg <= #TP {FRAME_WIDTH{1'b0}};
//	else if(spi_cs & spi_clk)
//		data_shreg <= #TP data_i;
//	else if(spi_clk)
//		data_shreg <= #TP IS_LSB_FIRST ? {1'b0, data_shreg[FRAME_WIDTH-1 : 1]} : {data_shreg[FRAME_WIDTH-2 : 0], 1'b0};
//end

TMR_register_complicated #(
    .SIGNAL_WIDTH(FRAME_WIDTH)
) data_shreg_TMR (
    .clk_iA             (clk_iA				),
    .clk_iB             (clk_iB				),
    .clk_iC             (clk_iC				),
    .reset_i            (reset_i			),
    
    .signal_in          (IS_LSB_FIRST ? {1'b0, data_shreg[FRAME_WIDTH-1 : 1]} : {data_shreg[FRAME_WIDTH-2 : 0], 1'b0}),
    .reset_signal_i     (data_i				),
    .reset_condition_i  (spi_cs & spi_clk	),
    .true_condition_i   (spi_clk			),
    
    .signal_out         (data_shreg			),
    .detected_seu_o     (data_shreg_seu		)
);

endmodule
