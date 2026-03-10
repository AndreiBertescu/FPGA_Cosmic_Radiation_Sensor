`timescale 1ns / 1ns

module TMR_register_simple #(
    parameter SIGNAL_WIDTH = 1,
    parameter IS_RESET_ACTIVE_LOW = 0
)(
    input                        clk_iA,
    input                        clk_iB,
    input                        clk_iC,
    input                        reset_i,

    input[SIGNAL_WIDTH - 1 : 0]  signal_in,
    input                        true_condition_i,

    output[SIGNAL_WIDTH - 1 : 0] signal_out,
    output                       detected_seu_o
);

    (* DONT_TOUCH="true" *) reg[SIGNAL_WIDTH - 1 : 0] sgn_A;
    (* DONT_TOUCH="true" *) reg[SIGNAL_WIDTH - 1 : 0] sgn_B;
    (* DONT_TOUCH="true" *) reg[SIGNAL_WIDTH - 1 : 0] sgn_C;

    generate
        if(IS_RESET_ACTIVE_LOW) begin

        always @(posedge clk_iA or negedge reset_i) begin 
            if (~reset_i)
                sgn_A <= {SIGNAL_WIDTH {1'b0}};
            else if (true_condition_i)
                sgn_A <= signal_in;
        end  
        always @(posedge clk_iB or negedge reset_i) begin
            if (~reset_i)
                sgn_B <= {SIGNAL_WIDTH {1'b0}};
            else if (true_condition_i)
                sgn_B <= signal_in;
        end  
        always @(posedge clk_iC or negedge reset_i) begin
            if (~reset_i)
                sgn_C <= {SIGNAL_WIDTH {1'b0}};
            else if (true_condition_i)
                sgn_C <= signal_in;
        end

        end else begin

        always @(posedge clk_iA or posedge reset_i) begin 
            if (reset_i)
                sgn_A <= {SIGNAL_WIDTH {1'b0}};
            else if (true_condition_i)
                sgn_A <= signal_in;
        end  
        always @(posedge clk_iB or posedge reset_i) begin
            if (reset_i)
                sgn_B <= {SIGNAL_WIDTH {1'b0}};
            else if (true_condition_i)
                sgn_B <= signal_in;
        end  
        always @(posedge clk_iC or posedge reset_i) begin
            if (reset_i)
                sgn_C <= {SIGNAL_WIDTH {1'b0}};
            else if (true_condition_i)
                sgn_C <= signal_in;
        end

        end
    endgenerate

    assign signal_out = (sgn_A & sgn_B) | (sgn_A & sgn_C) | (sgn_B & sgn_C);
    assign detected_seu_o = |((sgn_A & (~sgn_B)) | ((~sgn_A) & sgn_C) | (sgn_B & (~sgn_C)));

endmodule
