`timescale 1ns / 1ns

module clock_divider #(
    parameter FREQ_IN    = 100_000_000,  // 100 MHz
    parameter FREQ_OUT   = 9600,
    parameter MAKE_PULSE = 0
)(
    input       clk,
    input       reset_i,
    output      clk_o
);  

// MUST ADD THE LINE BELOW TO CONSTRAINTS FOR VIVADO TO DETECT clk_o AS AN ACTUAL CLOCK
// create_generated_clock -name clk_o -source [get_ports <input clock>] -divide_by <ammount> [get_nets <output clock>]
// Names are relative to the parent module where clock_divider is instantiated

    localparam COUNT_MAX = FREQ_IN / FREQ_OUT;
    reg [$clog2(COUNT_MAX)-1:0] counter;
    reg clk_i;


    // Output clock buffer
    BUFG BUFG_inst (
      .O(clk_o),
      .I(clk_i)
    );
   
    
    // Clock divider counter
    always @(posedge clk or posedge reset_i) begin
        if (reset_i)
            counter  <= {$clog2(COUNT_MAX){1'b0}};
        else if (counter == COUNT_MAX - 1)
            counter  <= {$clog2(COUNT_MAX){1'b0}};
        else
            counter  <= counter + 1;
    end

    // Output clock signal
    always @(posedge clk) begin
        if(MAKE_PULSE)
            clk_i <=  (counter == COUNT_MAX/2);
        else
            clk_i <=  (counter < COUNT_MAX/2);
    end

endmodule