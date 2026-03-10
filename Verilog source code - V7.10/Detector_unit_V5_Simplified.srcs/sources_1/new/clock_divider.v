`timescale 1ns / 1ns

module clock_divider #(
    parameter FREQ_IN    = 100_000_000,  // 100 MHz
    parameter FREQ_OUT   = 9600,
    parameter MAKE_PULSE = 0
)(
    input       clk_iA,
    input       clk_iB,
    input       clk_iC,
    input       reset_i,
	
    output reg  clk_o,
	output		counter_seu
);  

    localparam COUNT_MAX = FREQ_IN / FREQ_OUT;
    wire [$clog2(COUNT_MAX)-1:0] counter;
    
    // Clock divider counter
	TMR_register #(
	  .SIGNAL_WIDTH($clog2(COUNT_MAX))
	) counter_TMR (
	  .clk_iA             (clk_iA),
	  .clk_iB             (clk_iB),
	  .clk_iC             (clk_iC),
	  .reset_i            (reset_i),

	  .signal_in          (counter + 1'b1),
	  .reset_condition_i  (counter == COUNT_MAX - 1),
	  .true_condition_i   (1'b1),

	  .signal_out         (counter),
	  .detected_seu_o     (counter_seu)
	);

    // Output clock signal
    always @(posedge clk_iA or posedge reset_i) begin
		if(reset_i)
			clk_o <= 1'b0;
		else if(MAKE_PULSE)
            clk_o <= (counter == COUNT_MAX/2);
        else
            clk_o <= (counter < COUNT_MAX/2);
    end

endmodule