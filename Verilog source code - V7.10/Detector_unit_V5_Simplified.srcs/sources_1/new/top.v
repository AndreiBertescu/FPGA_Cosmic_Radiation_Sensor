`timescale 1ns / 1ps

module top (
   input   clk_proc_in_p,
   input   clk_proc_in_n,
    
   input   lvds_spi_io0_p,
   input   lvds_spi_io0_n,
   output  lvds_spi_io1_p,
   output  lvds_spi_io1_n,
   input   lvds_spi_sck_p,
   input   lvds_spi_sck_n,
   input   lvds_spi_cs_p,
   input   lvds_spi_cs_n
);

    localparam TP                   = 1;
    localparam ADDR_WIDTH           = 11;
    localparam DATA_WIDTH           = 18;
    localparam NR_DET_ELEM_BRAM     = 256; // 356 MAX
    localparam NR_DET_ELEM_LUTRAM   = 0;   // 40 MAX - 20 WORKS
    localparam NR_DET_ELEM          = NR_DET_ELEM_BRAM + NR_DET_ELEM_LUTRAM;
    localparam OUTPUT_FIFO_DEPTH    = 256; // 256
    
    wire                                clk_iA;
    wire                                clk_iB;
    wire                                clk_iC;
    wire                                locked;
	reg [2 : 0] 						reset_FF;
	wire 		 						reset;
	
    wire                                started_o;
	wire                                busy_flat_o;
	wire								start_strobe;

	wire								pop_fifo_i;
	wire [ADDR_WIDTH - 1 : 0]           selected_bram_seu_addr_o;
	wire [DATA_WIDTH - 1 : 0]           selected_bram_seu_bitmap_o;
	wire [$clog2(NR_DET_ELEM) - 1 : 0]  selected_bram_index_o;
	wire                                selected_logic_seu_o;
	wire [16 - 1 : 0]                   selected_scan_timer_o;
	wire								is_fifo_empty_o;
	wire								is_fifo_almost_empty_o;

	wire [9 - 1 : 0]                    inj_err_index_i;
	wire [ADDR_WIDTH - 1 : 0]           inj_err_address_i;
	wire [DATA_WIDTH - 1 : 0]           inj_err_data_i;
	wire                                inj_err_valid_i;
	
	wire [80 - 1 : 0]                   data_i;
	wire [16 - 1 : 0]                   sem_error_counter;
	wire                                status_uncorrectable;
	wire                                brown_out;
	
	wire 								brown_out_seu;
	wire 								error_counter_seu;
	wire 								couner_seu;
	wire                                spi_seu;
	wire                                logic_seu;
	
	wire [8 - 1 : 0]					checksum_o;
	wire                                status_parity_bit;
	
	wire                                spi_cs_i;
	wire                                spi_clk_i;
	wire                                spi_data_o;
	wire                                spi_data_i;


	// Main clock
	clk_wiz_0 clk_wiz_inst (
		.clk_in1_p	(clk_proc_in_p),
		.clk_in1_n	(clk_proc_in_n),
		.locked   	(locked),

		.clk_out1 	(clk_iA),
		.clk_out2 	(clk_iB),
		.clk_out3 	(clk_iC)
	); 

	// Reset structure
	always @(posedge clk_iA or negedge locked) begin
		if (~locked) begin
			reset_FF <= #TP 3'h7;
		end else begin
			reset_FF <= #TP {reset_FF[1:0], 1'b0};
		end
	end
	assign reset = reset_FF[2];
	
	
	// Brown-out detection
    TMR_register_simple #(
        .SIGNAL_WIDTH       (1)
    ) brownout_TMR (
        .clk_iA             (clk_iA     ),
        .clk_iB             (clk_iB     ),
        .clk_iC             (clk_iC     ),
        .reset_i            (reset      ),
    
        .signal_in          (1'b1       ),
        .true_condition_i   (started_o  ),
    
        .signal_out         (brown_out  ),
        .detected_seu_o     (brown_out_seu)
    );
	
	// Logic SEU register
	TMR_register #(
	  .SIGNAL_WIDTH(1)
	) logic_seu_TMR (
	    .clk_iA             (clk_iA		),
	    .clk_iB             (clk_iB		),
	    .clk_iC             (clk_iC		),
	    .reset_i            (reset	    ),
	    
	    .signal_in          (1'b1		),
	    .reset_condition_i  (started_o	),
	    .true_condition_i   (selected_logic_seu_o | brown_out_seu | error_counter_seu | couner_seu | spi_seu),
	    
	    .signal_out         (logic_seu	),
	    .detected_seu_o     (			)
	);


	// Detector unit
	clock_divider #(
        .FREQ_IN    		(10_000_000 ),
        .FREQ_OUT   		(1_000      ),
        .MAKE_PULSE 		(1          )
    ) start_generator_TMR (	
		.clk_iA     		(clk_iA		),
		.clk_iB     		(clk_iB		),
		.clk_iC     		(clk_iC		),
        .reset_i    		(reset      ),
		
        .clk_o      		(start_strobe),
		.counter_seu		(couner_seu	)
    );
	
	detector_unit #(
		.TP                 		(TP         				),
		.ADDR_WIDTH         		(ADDR_WIDTH         		),
		.DATA_WIDTH         		(DATA_WIDTH         		),
		.NR_DET_ELEM_BRAM           (NR_DET_ELEM_BRAM           ),
		.NR_DET_ELEM_LUTRAM         (NR_DET_ELEM_LUTRAM         ),
		.OUTPUT_FIFO_DEPTH          (OUTPUT_FIFO_DEPTH          )
	) detector_unit_0 (
		.clk_iA						(clk_iA						),
		.clk_iB						(clk_iB						),
		.clk_iC						(clk_iC						),
		.reset_i					(reset   					),
		.start_posedge_i			(start_strobe				),
		.busy_flat_o				(busy_flat_o				),

		.pop_fifo_i					(started_o     				),
		.selected_bram_seu_addr_o	(selected_bram_seu_addr_o	),
		.selected_bram_seu_bitmap_o	(selected_bram_seu_bitmap_o	),
		.selected_bram_index_o		(selected_bram_index_o      ),
		.selected_logic_seu_o		(selected_logic_seu_o		),
		.selected_scan_timer_o      (selected_scan_timer_o      ),
		.is_fifo_empty_o			(is_fifo_empty_o			),
        .is_fifo_almost_empty_o     (is_fifo_almost_empty_o     ),

		.inj_err_index_i			(inj_err_index_i			),
		.inj_err_address_i			(inj_err_address_i			),
		.inj_err_data_i				(inj_err_data_i				),
		.inj_err_valid_i			(inj_err_valid_i			)
	);
	
	
	// SEM wrapper: IP and ICAPE2, FRAME_ECC2 primitives
	sem_wrapper sem_wrapper_inst (
	  .clk_iA             	 		  (clk_iA				),
	  .clk_iB             	 		  (clk_iB				),
	  .clk_iC             	 		  (clk_iC				),
	  .reset_i            	 		  (reset				),
							  
	  .status_heartbeat      		  (						),
	  .status_initialization 		  (						),
	  .status_observation    		  (						),
	  .status_correction     		  (						),
	  .status_classification 		  (						),
	  .status_injection      		  (						),
	  .status_essential      		  (						),
	  .status_uncorrectable  		  (status_uncorrectable	),
	  .error_counter  		 		  (sem_error_counter	),
	  .error_counter_seu  		 	  (error_counter_seu	),
									  
	  .inject_strobe         		  (1'b0					),
	  .inject_address        		  (40'b0				),
	  .inject_forced_start   		  (started_o			)
	);
	
	// Checksum generators - for SPI transmission
	checksum_generator #(
        .WIDTH_IN    (72 						),
        .WIDTH_OUT   (8 						)
    ) checksum_generator_inst (
        .signal_i    ({selected_scan_timer_o, 16-$clog2(NR_DET_ELEM), selected_bram_index_o, 5'b0, selected_bram_seu_addr_o, sem_error_counter[6-1 : 0], selected_bram_seu_bitmap_o}), // 16 + 16 + 16 + 24
        .signal_o    (  	                    ),
        .checksum_o  (checksum_o                )
    );
    
    assign status_parity_bit = (~is_fifo_almost_empty_o) ^ (~brown_out) ^ logic_seu ^ status_uncorrectable ^ sem_error_counter[1] ^ sem_error_counter[0] ^ 1'b1;
	
	
	// SPI packet mapping
    assign data_i[24-1 : 0]    = {sem_error_counter[8-1 : 2]        , selected_bram_seu_bitmap_o   };  // SEU Bitmap, SEM error counter  - 24
    assign data_i[40-1 : 24]   = {checksum_o[4-1 : 0], 1'b0         , selected_bram_seu_addr_o     };  // SEU address                    - 11 + 1 + 4 
    assign data_i[56-1 : 40]   = {checksum_o[8-1 : 4], {12-$clog2(NR_DET_ELEM){1'b0}}, selected_bram_index_o};  // SEU BRAM index        - 9 + 3 + 4 
    assign data_i[72-1 : 56]   = {selected_scan_timer_o                                            };  // SEU scan timer                 - 16  
    assign data_i[80-1 : 72]   = { ~is_fifo_almost_empty_o,                                            // 1 if there still is packets to transfer
                                   ~brown_out,                                                         // 1 if there was a brown-out
                                   logic_seu,
                                   status_uncorrectable,                                               // 1 if the SEM IP found an uncorrectable error
                                   sem_error_counter[1 : 0],
                                   1'b1,                                                               // reserved for further AI developments
                                   status_parity_bit};                                                 // odd parity
	
	// SPI transmitter
	spi_block_V3 #(
        .TP                 (TP         ),
        .FRAME_WIDTH      	(80        	),
        .SPI_MODE 	     	(0          ),
        .IS_LSB_FIRST     	(0			)
    ) spi_block (
		.clk_iA     		(clk_iA		),
		.clk_iB     		(clk_iB		),
		.clk_iC     		(clk_iC		),
        .reset_i            (reset      ),
		
		.data_i				(data_i 	),
		.started_o			(started_o	),
		.seu_o				(spi_seu	),

		.spi_cs_i			(spi_data_i	),
		.spi_clk_i			(spi_clk_i  ),
		.spi_data_o			(spi_data_o	),
		.spi_data_i			(			)
    );


	// VIO
    `ifdef SYNTHESIS
		assign inj_err_valid_i   = 'b0;
		assign inj_err_index_i   = 'b0;
		assign inj_err_address_i = 'b0;
		assign inj_err_data_i    = 'b0;
		
    `else
		vio_tb #(
			.TP                	(TP                          ),
			.ADDR_WIDTH        	(ADDR_WIDTH                  ),
			.DATA_WIDTH        	(DATA_WIDTH                  ),
			.NR_DET_ELEM       	(NR_DET_ELEM                 )
		) VIO_TB (
			.clk_i             	(clk_iA	                  	 ),
			.reset_i           	(reset                       ),
			.start_o           	(				             ),

			.pop_fifo_o			(					 		 ),
			.bram_seu_addr_i    (selected_bram_seu_addr_o    ),
			.bram_seu_bitmap_i  (selected_bram_seu_bitmap_o  ),
			.bram_seu_index_i   (selected_bram_index_o       ),
			.logic_seu_i        (selected_logic_seu_o        ),
			.scan_timer_i       (selected_scan_timer_o       ),
			.busy_i             (busy_flat_o                 ),
			.is_fifo_empty_i    (is_fifo_empty_o             ),

			.inj_err_index_o   	(inj_err_index_i             ),
			.inj_err_address_o 	(inj_err_address_i           ),
			.inj_err_data_o    	(inj_err_data_i              ),
			.inj_err_valid_o   	(inj_err_valid_i             )
		);
    `endif


    // REAL SPI Buffers
    IBUFDS #(
      .DIFF_TERM    ("FALSE"        ),
      .IOSTANDARD   ("DEFAULT"      )
   ) IBUFDS_io0 (
      .I            (lvds_spi_io0_p ),
      .IB           (lvds_spi_io0_n ),
      .O            (spi_data_i     )
   );

   OBUFTDS #(
      .IOSTANDARD   ("DEFAULT"      ),
      .SLEW         ("FAST"         )
   ) OBUFTDS_io1 (
      .O            (lvds_spi_io1_p ),
      .OB           (lvds_spi_io1_n ),
      .I            (spi_data_o     ),
      .T            (spi_data_i     )
   );

   IBUFDS #(
      .DIFF_TERM    ("FALSE"        ),
      .IOSTANDARD   ("DEFAULT"      )
   ) IBUFDS_sck (
      .I            (lvds_spi_sck_p ),
      .IB           (lvds_spi_sck_n ),
      .O            (spi_clk_i      )
   );

   IBUFDS #(
      .DIFF_TERM    ("FALSE"        ),
      .IOSTANDARD   ("DEFAULT"      )
   ) IBUFDS_cs (
      .I            (lvds_spi_cs_p ),
      .IB           (lvds_spi_cs_n ),
      .O            (spi_cs_i      )
   );

endmodule