`timescale 1ns / 1ns

module xadc_wrapper_tb();

localparam HALF_100_MHZ_CLOCK_PERIOD = 5; //half of the period of the 100 MHz clock
localparam TP = 1;

reg clk;
reg reset_i;

wire temp_warning;
wire temp_alarm;
wire vcc_int_alarm;
wire vcc_aux_alarm;

wire[12-1 : 0] temp;
wire[12-1 : 0] vcc_int;
wire[12-1 : 0] vcc_aux;
wire[12-1 : 0] vp_vn;


// Clock
initial begin
	clk <= 1'b0;
	forever begin
		#HALF_100_MHZ_CLOCK_PERIOD clk <= ~clk;
	end
end


// Main test loop
initial begin
    repeat (10) @(negedge clk);
    reset_i = 1;

    // Wait reset
    repeat (10) @(negedge clk);
    reset_i = 0;

    repeat (40000) @(posedge clk);
    $finish;
end


// DUV
xadc_wrapper DUV(
    .clk              (clk    ),
    .reset_i          (reset_i),

    .vp_i             (1'b0   ),
    .vn_i             (1'b0   ),
        
    .temp_warning_o   (temp_warning   ),
    .temp_alarm_o     (temp_alarm     ),
    .vcc_int_alarm_o  (vcc_int_alarm  ),
    .vcc_aux_alarm_o  (vcc_aux_alarm  ),
    
    .temp_o           (temp   ),
    .vcc_int_o        (vcc_int),
    .vcc_aux_o        (vcc_aux),
    .vp_vn_o          (vp_vn  )
);

endmodule
