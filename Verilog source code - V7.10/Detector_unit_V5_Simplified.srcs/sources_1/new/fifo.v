`timescale 1ns / 1ps

module fifo #(
	parameter TP		  = 1,
    parameter DATA_WIDTH  = 35,
    parameter ECC_WIDTH   = 7,
    parameter DEPTH       = 16
) (
    input                           clk_iA,
    input                           clk_iB,
    input                           clk_iC,
    input                           reset_i,

    input                           write_enable,
    input [DATA_WIDTH - 1 : 0]      data_i,

    input                           read_enable,
    output [DATA_WIDTH - 1 : 0]     data_o,
	output 							detected_seu_o,

    output                          full,
    output                          empty,
    output                          almost_empty
);

    integer i;
    wire [$clog2(DEPTH) : 0] write_ptr;
    wire [$clog2(DEPTH) : 0] read_ptr;
    reg [DATA_WIDTH + ECC_WIDTH - 1 : 0] fifo [DEPTH -1 : 0];
	
    wire [DATA_WIDTH + ECC_WIDTH - 1 : 0]   data_ecc_in;
    wire [DATA_WIDTH + ECC_WIDTH - 1 : 0]   data_ecc_out;
	wire sbit_err, dbit_err;
	
    assign data_ecc_out = fifo[read_ptr[$clog2(DEPTH) - 1: 0]];
    assign detected_seu_o = sbit_err | dbit_err;
	
	
	// Main fifo memory and ECC encoder/decoder
	ecc_0_e ecc_0_e_inst(
      .ecc_data_in      (data_i                                                 ),
      .ecc_data_out     (data_ecc_in[DATA_WIDTH - 1 : 0]                        ),
      .ecc_chkbits_out  (data_ecc_in[DATA_WIDTH + ECC_WIDTH - 1 : DATA_WIDTH]   )
    );
	
	always @(posedge clk_iA or posedge reset_i) begin
      if (reset_i) begin
        for (i = 0; i < DEPTH; i = i + 1) begin
          fifo[i] <= #TP {DATA_WIDTH{1'b0}};
        end
      end else if (write_enable & !full) begin
        fifo[write_ptr] <= #TP data_ecc_in;
      end
    end
	
	ecc_0_d ecc_0_d_inst (
      .ecc_correct_n    (1'b0                                                   ),
      .ecc_data_in      (data_ecc_out[DATA_WIDTH - 1 : 0]                       ),
      .ecc_chkbits_in   (data_ecc_out[DATA_WIDTH + ECC_WIDTH - 1 : DATA_WIDTH]  ),
      .ecc_data_out     (data_o                                                 ),
      .ecc_sbit_err     (sbit_err                                               ),
      .ecc_dbit_err     (dbit_err                                               )
    );
	

    //write_ptr & fifo
	TMR_register_simple #(
		.SIGNAL_WIDTH       ($clog2(DEPTH) + 1)
	) write_ptr_TMR (
		.clk_iA             (clk_iA),
		.clk_iB             (clk_iB),
		.clk_iC             (clk_iC),
		.reset_i            (reset_i),

		.signal_in          (write_ptr + 1'b1),
		.true_condition_i   (write_enable & !full),

		.signal_out         (write_ptr),
		.detected_seu_o     ()
	);


    //read_ptr & data_out
	TMR_register_simple #(
		.SIGNAL_WIDTH       ($clog2(DEPTH) + 1)
	) read_ptr_TMR (
		.clk_iA             (clk_iA),
		.clk_iB             (clk_iB),
		.clk_iC             (clk_iC),
		.reset_i            (reset_i),

		.signal_in          (read_ptr + 1'b1),
		.true_condition_i   (read_enable & !empty),

		.signal_out         (read_ptr),
		.detected_seu_o     ()
	);


    assign full  = (write_ptr[$clog2(DEPTH) - 1: 0] == read_ptr[$clog2(DEPTH) - 1: 0]) & (write_ptr[$clog2(DEPTH)] ^ read_ptr[$clog2(DEPTH)]);
    assign empty = (write_ptr == read_ptr);
	assign almost_empty = (write_ptr == (read_ptr + 1)) | empty;
	//assign almost_empty = (write_ptr[$clog2(DEPTH) - 1: 0] == (read_ptr[$clog2(DEPTH) - 1: 0] + 1)) | empty;

endmodule
