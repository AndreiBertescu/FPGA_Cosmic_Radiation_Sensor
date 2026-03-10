`timescale 1ns / 1ns

module detector_unit #(
    parameter TP                 = 1,
    parameter ADDR_WIDTH         = 11,
    parameter DATA_WIDTH         = 18,
    parameter NR_DET_ELEM_BRAM   = 365,
    parameter NR_DET_ELEM_LUTRAM = 50,
    parameter NR_DET_ELEM        = NR_DET_ELEM_BRAM + NR_DET_ELEM_LUTRAM,
    parameter OUTPUT_FIFO_DEPTH  = 8
) (
    input                                     clk_iA,
    input                                     clk_iB,
    input                                     clk_iC,
    input                                     reset_i,
    input                                     start_posedge_i,
    output                                    busy_flat_o,

    input                                     pop_fifo_i,
    output [ADDR_WIDTH - 1 : 0]               selected_bram_seu_addr_o,
    output [DATA_WIDTH - 1 : 0]               selected_bram_seu_bitmap_o,
    output [$clog2(NR_DET_ELEM) - 1 : 0]      selected_bram_index_o,
    output                                    selected_logic_seu_o,
    output [16 - 1 : 0]                       selected_scan_timer_o,
    output                                    is_fifo_empty_o,
    output                                    is_fifo_almost_empty_o,

    input [9 - 1 : 0]                         inj_err_index_i,
    input [ADDR_WIDTH - 1 : 0]                inj_err_address_i,
    input [DATA_WIDTH - 1 : 0]                inj_err_data_i,
    input                                     inj_err_valid_i
);
    
    // Detector inputs
	wire [16 - 1 : 0]						  scan_timer;
    wire [NR_DET_ELEM * ADDR_WIDTH-1 : 0]     bram_seu_addr;
    wire [NR_DET_ELEM * DATA_WIDTH-1 : 0]     bram_seu_bitmap;
    wire [0 : NR_DET_ELEM - 1]                bram_seu_valid;
    wire [0 : NR_DET_ELEM - 1]                logic_seu;
    wire [0 : NR_DET_ELEM - 1]                busy;
    assign busy_flat_o = |busy;
    
    // Pipeline registers
    reg [NR_DET_ELEM * ADDR_WIDTH-1 : 0]      bram_seu_addr_r;
    reg [NR_DET_ELEM * DATA_WIDTH-1 : 0]      bram_seu_bitmap_r;
    reg [0 : NR_DET_ELEM - 1]                 bram_seu_valid_r;
    reg [0 : NR_DET_ELEM - 1]                 logic_seu_r;
    
    reg [NR_DET_ELEM * ADDR_WIDTH-1 : 0]      bram_seu_addr_rr;
    reg [NR_DET_ELEM * DATA_WIDTH-1 : 0]      bram_seu_bitmap_rr;
    reg [0 : $clog2(NR_DET_ELEM) - 1]         bram_seu_valid_rr;
    reg [0 : NR_DET_ELEM - 1]                 logic_seu_rr;
    wire                                      encoder_valid_r;

    // Encoder signals
    wire                               encoder_valid;
    wire [$clog2(NR_DET_ELEM) - 1 : 0] active_detector_index;
    wire [$clog2(NR_DET_ELEM) - 1 : 0] active_detector_index_corrected;
    
    // FIFO logic SEU
    wire                               output_logic_seu;
    wire                               encoder_logic_seu;
    wire                               fifo_logic_seu;
    wire                               scan_timer_seu;
    assign                             selected_logic_seu_o = output_logic_seu | fifo_logic_seu | encoder_logic_seu | scan_timer_seu;

    // Detector modules - scans a BRAM to see changes in its memory
    genvar j;
    generate
      for (j = 0; j < NR_DET_ELEM; j = j + 1) begin : gen_det_elem
        wire inj_err_valid_i_individual;
        assign inj_err_valid_i_individual = inj_err_valid_i & (j == inj_err_index_i);

        BRAM_SEU_detector #(
            .TP                 (1                                                                ),
            .INDEX              (j                                                                ),
            .ADDR_WIDTH         (ADDR_WIDTH                                                       ),
            .DATA_WIDTH         (DATA_WIDTH                                                       ),
            .USE_LUTRAM         (j >= NR_DET_ELEM_BRAM                                             )
        ) DETECTOR (
            .clk_iA             (clk_iA                                                           ),
            .clk_iB             (clk_iB                                                           ),
            .clk_iC             (clk_iC                                                           ),
            .reset_i            (reset_i                                                          ),
            .start_i            (start_posedge_i                                                  ),

            .bram_seu_addr_o    (bram_seu_addr      [ADDR_WIDTH * j         +: ADDR_WIDTH        ]),
            .bram_seu_bitmap_o  (bram_seu_bitmap    [DATA_WIDTH * j         +: DATA_WIDTH        ]),
            .bram_seu_valid_o   (bram_seu_valid     [j]                                           ),
            .logic_seu_o        (logic_seu          [j]                                           ),
            .busy_o             (busy               [j]                                           ),
            .reset_prot_cntr_i  (pop_fifo_i                                                       ),

            .inj_err_address_i  (inj_err_address_i                                                ),
            .inj_err_data_i     (inj_err_data_i                                                   ),
            .inj_err_valid_i    (inj_err_valid_i_individual                                       )
        );
      end
    endgenerate
	
	
	// TMR Timer
	TMR_register_simple #(
        .SIGNAL_WIDTH       (16					)
    ) scan_timer_TMR (
        .clk_iA             (clk_iA 			),
        .clk_iB             (clk_iB 			),
        .clk_iC             (clk_iC 			),
        .reset_i            (reset_i			),
    
        .signal_in          (scan_timer + 16'b1 ),
        .true_condition_i   (start_posedge_i	),
    
        .signal_out         (scan_timer	        ),
        .detected_seu_o     (scan_timer_seu		)
    );
    
    
    // Pipeline registers
    always @(posedge clk_iA or posedge reset_i) begin
		if(reset_i) begin
			bram_seu_addr_r     <= 'b0;
			bram_seu_bitmap_r   <= 'b0;
			bram_seu_valid_r    <= 'b0;
			logic_seu_r         <= 'b0;

			bram_seu_addr_rr    <= 'b0;
			bram_seu_bitmap_rr  <= 'b0;
			bram_seu_valid_rr   <= 'b0;
			logic_seu_rr        <= 'b0;
		end else begin
			bram_seu_addr_r     <= bram_seu_addr;
			bram_seu_bitmap_r   <= bram_seu_bitmap;
			bram_seu_valid_r    <= bram_seu_valid;
			logic_seu_r         <= logic_seu;
			
			bram_seu_addr_rr    <= bram_seu_addr_r;
			bram_seu_bitmap_rr  <= bram_seu_bitmap_r;
			bram_seu_valid_rr   <= active_detector_index;
			logic_seu_rr        <= logic_seu_r;
		end
    end
    
    TMR_register_simple #(
        .SIGNAL_WIDTH       (1					)
    ) total_seu_maj_voted_TMR (
        .clk_iA             (clk_iA 			),
        .clk_iB             (clk_iB 			),
        .clk_iC             (clk_iC 			),
        .reset_i            (reset_i			),
    
        .signal_in          (encoder_valid		),
        .true_condition_i   (1'b1				),
    
        .signal_out         (encoder_valid_r	),
        .detected_seu_o     (encoder_logic_seu	)
    );


    // Priority encoder - gets the active detector index
    param_encoder #(
        .NR_ELEM		(NR_DET_ELEM			),
        .IS_REVERSED	(0						)
    ) param_encoder_active_detector_index (
        .in				(bram_seu_valid_r		),
        .out			(active_detector_index	),
        .valid_o		(encoder_valid			)
    );
    assign active_detector_index_corrected = NR_DET_ELEM - bram_seu_valid_rr - 1;

    
    // FIFOs
	fifo #(
        .DATA_WIDTH     (ADDR_WIDTH + DATA_WIDTH + $clog2(356+40) + 1 + 16		    ),
        .DEPTH          (OUTPUT_FIFO_DEPTH        									)
    ) output_fifo (		
        .clk_iA         (clk_iA                  									),
        .clk_iB         (clk_iB                  									),
        .clk_iC         (clk_iC                  									),
        .reset_i        (reset_i                 									),
		
        .write_enable   (encoder_valid_r            								),
        .data_i         ({{(9 - $clog2(NR_DET_ELEM)){1'b0}},      // Filler
                          bram_seu_addr_rr [ADDR_WIDTH * active_detector_index_corrected +: ADDR_WIDTH],
						  bram_seu_bitmap_rr [DATA_WIDTH * active_detector_index_corrected +: DATA_WIDTH],
						  active_detector_index_corrected,
						  logic_seu_rr [active_detector_index_corrected],
						  scan_timer}),

        .read_enable    (pop_fifo_i               									),
        .data_o         ({selected_bram_seu_addr_o, selected_bram_seu_bitmap_o, selected_bram_index_o, output_logic_seu, selected_scan_timer_o}),
		.detected_seu_o (fifo_logic_seu												),

        .full           (                         									),
        .empty          (is_fifo_empty_o          									),
        .almost_empty   (is_fifo_almost_empty_o   									)
    );

endmodule
