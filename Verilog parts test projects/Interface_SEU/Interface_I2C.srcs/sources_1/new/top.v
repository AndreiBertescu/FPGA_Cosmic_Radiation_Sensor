`timescale 1ns / 1ns

module top(
    input 	clk_proc_in_p,
    input 	clk_proc_in_n
);

localparam TP = 1;

wire        	clk;
wire        	locked;
reg [2 : 0] 	reset_FF;
wire 			reset;
	
wire [39 : 0] 	inject_address;
wire        	inject_strobe;
reg         	inject_strobe_d;
wire        	inject_forced_start;
reg         	inject_forced_start_d;

wire        	status_heartbeat;
wire        	status_initialization;
wire        	status_observation;
wire        	status_correction;
wire        	status_classification;
wire        	status_injection;
wire        	status_essential;
wire        	status_uncorrectable;
wire [16-1 : 0]	error_counter;
	

// Main clock
clk_wiz_0 clk_wiz_inst (
    .clk_in1_p	(clk_proc_in_p   ),
    .clk_in1_n	(clk_proc_in_n   ),
    .locked   	(locked          ),
    .clk_out1 	(clk             )
); 

// Reset structure
always @(posedge clk or negedge locked) begin
	if (~locked) begin
		reset_FF <= #TP 3'h7;
	end else begin
		reset_FF <= #TP {reset_FF[1:0], 1'b0};
	end
end
assign reset = reset_FF[2];


// SEM wrapper: IP and ICAPE2, FRAME_ECC2 primitives
sem_wrapper sem_wrapper_inst (
  .clk_iA             	 		  (clk									),
  .clk_iB             	 		  (clk									),
  .clk_iC             	 		  (clk									),
  .reset_i            	 		  (reset								),
						  
  .status_heartbeat      		  (status_heartbeat						),
  .status_initialization 		  (status_initialization				),
  .status_observation    		  (status_observation					),
  .status_correction     		  (status_correction					),
  .status_classification 		  (status_classification				),
  .status_injection      		  (status_injection						),
  .status_essential      		  (status_essential						),
  .status_uncorrectable  		  (status_uncorrectable					),
  .error_counter  		 		  (error_counter						),
								  
  .inject_strobe         		  (inject_strobe & ~inject_strobe_d	    ),
  .inject_address        		  (inject_address						),
  .inject_forced_start   		  (inject_forced_start & ~inject_forced_start_d)

);


// VIO
always @(posedge clk) begin
    inject_strobe_d <= inject_strobe;
    inject_forced_start_d <= inject_forced_start;
end

vio_0 VIRTUAL_IO (
    .clk            (clk             	   		),
	
    .probe_out0     (inject_strobe				),
    .probe_out1     (inject_address	  			),
    .probe_out2     (inject_forced_start	  	),
    
    .probe_in0    	(status_heartbeat			),
    .probe_in1  	(status_initialization		),
    .probe_in2   	(status_observation			),
    .probe_in3      (status_correction			),
    .probe_in4      (status_classification		),
    .probe_in5		(status_injection			),
    .probe_in6		(status_essential			),
    .probe_in7		(status_uncorrectable		),
    .probe_in8		(error_counter				)
);

endmodule

