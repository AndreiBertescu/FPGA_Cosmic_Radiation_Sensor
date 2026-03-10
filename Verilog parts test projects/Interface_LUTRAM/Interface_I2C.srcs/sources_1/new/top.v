`timescale 1ns / 1ns

module top(
    input 				clk,
    
    input [18-1 : 0] 	wr_data,
    input [11-1 : 0] 	wr_addr,
    input  				wea,
	
    input [11-1 : 0] 	addr_value,
//    output [18-1 : 0]   read_data_bram,
    output [18-1 : 0]   read_data_lutram
);

//    // Instantiate BRAM
//    blk_mem_gen_0 BRAM_MEMORY (
//        .clka   (clk				),
//        .clkb   (clk				),
				
//        .wea    (wea				),
//        .addra  (wr_addr			),
//        .dina   (wr_data			),
			
//        .addrb  (addr_value			),
//        .doutb  (read_data_bram		)
//    );
	
	// Instantiate LUTRAM
    lut_ram #(
		.WIDTH	(18					),
		.DEPTH	(2048				),
		.INIT_A	(18'h15555			),
		.INIT_B	(18'h2AAAA			)
	) LUTRAM_MEMORY (		
        .clka   (clk				),
				
        .wea    (wea				),
        .addra  (wr_addr			),
        .dina   (wr_data			),
        
        .addrb  (addr_value			),
        .doutb  (read_data_lutram	)
    );

endmodule

