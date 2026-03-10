`timescale 1ns / 1ns

module top_tb();

localparam HALF_100_MHZ_CLOCK_PERIOD = 5; //half of the period of the 100 MHz clock
localparam TP = 1;

reg clk;
reg reset_i;
wire tx;

wire sda;
wire scl;
pullup(sda);
pullup(scl);


// Clock
initial begin
	clk <= 1'b0;
	forever begin
		#HALF_100_MHZ_CLOCK_PERIOD clk <= ~clk;
	end
end


// Main test loop
initial begin
    reset_i = 1;

    // Wait reset
    repeat (10) @(posedge clk);
    reset_i = 0;

    repeat (400000) @(posedge clk);
    $finish;
end


// DUV
top DUV(
    .sys_clock  (clk    ),
    
    .btn_c      (1'b0   ),   // posedge reset
    .btn_l      (1'b0   ),   // read  eeprom 
    .btn_r      (1'b0   ),   // write eeprom
    .btn_u      (1'b0   ),   // push to fifo
    .btn_d      (1'b0   ),   // pop from fifo

    .sw         (1'b0   ),
    .led        (       ),
    
    .rx         (1'b0   ),
    .tx         (tx     ),

    .sda        (sda    ),
    .scl        (scl    )
);

endmodule
