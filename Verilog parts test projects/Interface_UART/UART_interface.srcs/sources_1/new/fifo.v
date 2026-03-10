`timescale 1ns / 1ns

module fifo #(
    parameter DATA_WIDTH  = 18,
    parameter DEPTH       = 16
) (
    input                           clk,
    input                           rst_n,

    input                           write_enable,
    input [DATA_WIDTH - 1 : 0]      data_i,

    input                           read_enable,
    output reg [DATA_WIDTH - 1 : 0] data_o,

    output                          full,
    output                          empty
);

    reg [$clog2(DEPTH) - 1 : 0] write_ptr;
    reg [$clog2(DEPTH) - 1 : 0] read_ptr;
    reg [DATA_WIDTH - 1 : 0] fifo [DEPTH -1 : 0];


    //write_ptr & fifo
    always @(posedge clk) begin
      if (~rst_n) begin
        write_ptr <= 0;
      end else if (write_enable & !full) begin
        write_ptr <= write_ptr + 1;
        fifo[write_ptr] <= data_i;
      end
    end


    //read_ptr & data_out
    always @(posedge clk) begin
      if (~rst_n) begin
        read_ptr <= 0;
        data_o   <= 0;
      end else if (read_enable & !empty) begin
        read_ptr <= read_ptr + 1;
        data_o   <= fifo[read_ptr];
      end
    end


    assign full  = ((write_ptr + 1'b1) == read_ptr);
    assign empty = (write_ptr == read_ptr);

endmodule
