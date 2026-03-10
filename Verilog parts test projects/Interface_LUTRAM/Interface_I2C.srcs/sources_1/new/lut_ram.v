`timescale 1ns / 1ns

module lut_ram #(
	parameter WIDTH 	= 1,
	parameter DEPTH 	= 128,	           // Must be a power of 2, greater or equal than 128
	parameter INIT_A	= {WIDTH{1'b0}},   // The stored values will oscilate between the 2 INIT values, starting with INIT_A
	parameter INIT_B	= {WIDTH{1'b0}}
) (
    input 						clka, 
                        
    input  						wea,   
    input [$clog2(DEPTH)-1 : 0] addra, 
    input [WIDTH-1 : 0] 		dina,  
	                    
    input [$clog2(DEPTH)-1 : 0] addrb, 
    output reg [WIDTH-1 : 0]	doutb
);

	genvar 							i, j;
	wire [WIDTH-1 : 0] 				read_data [(DEPTH/128)-1 : 0];
	reg [WIDTH-1 : 0] 				read_data_pipe;
	reg [$clog2(DEPTH)-1-7 : 0] 	addrb_d;

	// Pipeline output registers
	always @(posedge clka) begin
		addrb_d			<= addrb[$clog2(DEPTH)-1 : 7];
		read_data_pipe 	<= read_data[addrb_d];
		doutb    		<= read_data_pipe;
	end
	
	
	// Dual-port distributed LUT RAM
	generate
    for (j = 0; j < DEPTH/128; j = j + 1) begin : bank_gen
		for (i = 0; i < WIDTH; i = i + 1) begin : gen_lutram
			RAM128X1D #(
			   .INIT    ({64{INIT_B[i], INIT_A[i]}})
			) RAM128X1D_inst (
			   .WCLK	(clka			), 
			   
			   .WE		(wea & (addra[$clog2(DEPTH)-1 : 7] == j)),
			   .A		(addra[7-1 : 0]	),        
			   .D		(dina[i]		),    
			   .SPO		(				),
				  
			   .DPRA	(addrb[7-1 : 0]	),  
			   .DPO		(read_data[j][i])       
			);
		end
    end
	endgenerate

endmodule
