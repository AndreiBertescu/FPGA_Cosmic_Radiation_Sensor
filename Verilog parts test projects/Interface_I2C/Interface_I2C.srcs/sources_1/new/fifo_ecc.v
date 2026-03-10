`timescale 1ns / 1ns

module fifo_ecc #(
    parameter DATA_WIDTH  = 8,
    parameter ECC_WIDTH   = 5,
    parameter DEPTH       = 16
) (
    input                           clk,
    input                           rst_n,

    input                           write_enable,
    input [DATA_WIDTH - 1 : 0]      data_i,

    input                           read_enable,
    output [DATA_WIDTH - 1 : 0]     data_o,

    output                          full,
    output                          empty,
    
    output                          sbit_err,
    output                          dbit_err
);
    
    reg [$clog2(DEPTH) - 1 : 0]             write_ptr;
    reg [$clog2(DEPTH) - 1 : 0]             read_ptr;
    wire [DATA_WIDTH + ECC_WIDTH - 1 : 0]   data_ecc_in;
    reg [DATA_WIDTH + ECC_WIDTH - 1 : 0]    data_ecc_out;
    reg [DATA_WIDTH + ECC_WIDTH - 1 : 0]    fifo [DEPTH - 1 : 0];


    //write_ptr & fifo
    ecc_8_e ecc_8_e_inst(
      .ecc_data_in      (data_i                                                 ),
      .ecc_data_out     (data_ecc_in[DATA_WIDTH - 1 : 0]                        ),
      .ecc_chkbits_out  (data_ecc_in[DATA_WIDTH + ECC_WIDTH - 1 : DATA_WIDTH]   )
    );

    always @(posedge clk) begin
      if (~rst_n) begin
        write_ptr <= 0;
      end else if (write_enable & !full) begin
        write_ptr <= write_ptr + 1;
        fifo[write_ptr] <= data_ecc_in;
      end
    end


    //read_ptr & data_out
    always @(posedge clk) begin
      if (~rst_n) begin
        read_ptr <= 0;
        data_ecc_out   <= 0;
      end else if (read_enable & !empty) begin
        read_ptr <= read_ptr + 1;
        data_ecc_out   <= fifo[read_ptr];
      end
    end
    
    ecc_8_d ecc_8_d_inst (
      .ecc_correct_n    (1'b0                                                   ),
      .ecc_data_in      (data_ecc_out[DATA_WIDTH - 1 : 0]                       ),
      .ecc_chkbits_in   (data_ecc_out[DATA_WIDTH + ECC_WIDTH - 1 : DATA_WIDTH]  ),
      .ecc_data_out     (data_o                                                 ),
      .ecc_sbit_err     (sbit_err                                               ),
      .ecc_dbit_err     (dbit_err                                               )
    );

    assign full  = ((write_ptr + 1'b1) == read_ptr);
    assign empty = (write_ptr == read_ptr);

endmodule
