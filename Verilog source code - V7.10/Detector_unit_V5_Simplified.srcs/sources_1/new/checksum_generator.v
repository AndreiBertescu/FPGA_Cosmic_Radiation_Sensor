`timescale 1ns / 1ns

module checksum_generator #(
    parameter WIDTH_IN   = 9,
    parameter WIDTH_OUT  = 4,
	parameter PADDED_WIDTH = (WIDTH_IN % WIDTH_OUT == 0) ? WIDTH_IN : (WIDTH_IN + WIDTH_OUT - (WIDTH_IN % WIDTH_OUT))
)(
    input  [WIDTH_IN-1 : 0]                   signal_i,
    output [PADDED_WIDTH + WIDTH_OUT - 1 : 0] signal_o,
    output [WIDTH_OUT-1 : 0]                  checksum_o
);  

	genvar i;
	wire [PADDED_WIDTH-1 : 0] padded_signal = (PADDED_WIDTH == WIDTH_IN) ? signal_i : {{(PADDED_WIDTH - WIDTH_IN){1'b0}}, signal_i};
    wire [WIDTH_OUT-1 : 0] partial_sum [PADDED_WIDTH/WIDTH_OUT - 1 : 0];
    
    generate
        assign partial_sum[0] = padded_signal[WIDTH_OUT-1 : 0];

        for(i = 1; i < PADDED_WIDTH/WIDTH_OUT; i = i+1) begin : gen_checksum
            assign partial_sum[i] = partial_sum[i - 1] ^ padded_signal[WIDTH_OUT*i +: WIDTH_OUT];
        end
    endgenerate
    
    assign checksum_o = partial_sum[PADDED_WIDTH/WIDTH_OUT - 1];
    assign signal_o = {checksum_o, padded_signal};

endmodule