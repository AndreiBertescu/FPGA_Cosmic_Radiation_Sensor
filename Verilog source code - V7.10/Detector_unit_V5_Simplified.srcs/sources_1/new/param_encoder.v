`timescale 1ns / 1ps

module param_encoder #(
    parameter NR_ELEM     = 10,
    parameter IS_REVERSED = 0
)(
    input  [        NR_ELEM - 1 : 0] in,
    output [$clog2(NR_ELEM) - 1 : 0] out,
    output                           valid_o
);

generate
  if (NR_ELEM == 2) begin
    assign out = IS_REVERSED ? in[0] : in[1];
    assign valid_o = |in;
  end else begin
    localparam FULL_NR_ELEM = 1 << $clog2(NR_ELEM); //1 << (NR_ELEM & (NR_ELEM - 1)) ? (1 << $clog2(NR_ELEM - 2)) : NR_ELEM;
    wire [FULL_NR_ELEM - 1 : 0] full_in;
    assign full_in = IS_REVERSED ? 
                    ((FULL_NR_ELEM == NR_ELEM) ? in : {in, {(FULL_NR_ELEM - NR_ELEM) {1'b0}}}) : 
                    ((FULL_NR_ELEM == NR_ELEM) ? in : {{(FULL_NR_ELEM - NR_ELEM) {1'b0}}, in}) ;

    wire valid_hi;
    wire valid_lo;
    wire [$clog2(FULL_NR_ELEM >> 1) - 1 : 0] out_hi;
    wire [$clog2(FULL_NR_ELEM >> 1) - 1 : 0] out_lo;

    param_encoder #(
        .NR_ELEM(FULL_NR_ELEM >> 1),
        .IS_REVERSED(IS_REVERSED)
    ) param_encoder_hi (
        .in(full_in[FULL_NR_ELEM-1 : (FULL_NR_ELEM>>1)]),
        .out(out_hi),
        .valid_o(valid_hi)
    );

    param_encoder #(
        .NR_ELEM(FULL_NR_ELEM >> 1),
        .IS_REVERSED(IS_REVERSED)
    ) param_encoder_lo (
        .in(full_in[(FULL_NR_ELEM>>1)-1 : 0]),
        .out(out_lo),
        .valid_o(valid_lo)
    );

    if (IS_REVERSED) begin
      assign out = {valid_lo, {valid_lo ? out_lo : out_hi}};
    end else begin
      assign out = {valid_hi, {valid_hi ? out_hi : out_lo}};
    end

    assign valid_o = valid_hi | valid_lo;
  end
endgenerate

endmodule
