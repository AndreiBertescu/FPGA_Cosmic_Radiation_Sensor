`timescale 1ns / 1ns

module counterTMR #(
    parameter TP        = 1,
    parameter WIDTH     = 9
)(
    input               clk_iA,
    input               clk_iB,
    input               clk_iC,
    input               reset_i,
    input               start_i,    
    output [WIDTH-1:0]  value_o,
    output              valid_o,
    output              seu_o           
);

wire [WIDTH-1:0] counter;
wire             counter_seu;
wire             started;
wire             started_seu;

assign value_o = counter;
assign valid_o = started;
assign seu_o   = counter_seu | started_seu;


// started
TMR_register #(
  .SIGNAL_WIDTH(1),
  .RESET_CONDITION_VALUE(1)
) started_TMR (
  .clk_iA             (clk_iA),
  .clk_iB             (clk_iB),
  .clk_iC             (clk_iC),
  .reset_i            (reset_i),

  .signal_in          (1'b0),
  .reset_condition_i  ((~started) & start_i),
  .true_condition_i   (started & (&counter)),

  .signal_out         (started),
  .detected_seu_o     (started_seu)
);


// counter
TMR_register_simple #(
    .SIGNAL_WIDTH       (WIDTH)
) counter_TMR (
    .clk_iA             (clk_iA),
    .clk_iB             (clk_iB),
    .clk_iC             (clk_iC),
    .reset_i            (reset_i),

    .signal_in          (counter + {{(WIDTH-1){1'b0}}, 1'b1}),
    .true_condition_i   (started),

    .signal_out         (counter),
    .detected_seu_o     (counter_seu)
);

endmodule
