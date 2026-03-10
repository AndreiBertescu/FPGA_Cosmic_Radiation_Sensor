`timescale 1ns / 1ns

module sem_wrapper(
  input         clk_iA,
  input         clk_iB,
  input         clk_iC,
  input 		reset_i,
  
  output        status_heartbeat,
  output        status_initialization,
  output        status_observation,
  output        status_correction,
  output        status_classification,
  output        status_injection,
  output        status_essential,
  output        status_uncorrectable,
  output [15:0] error_counter,
  output 		error_counter_seu,
  
  input         inject_strobe,
  input [39:0]  inject_address,
  input 		inject_forced_start
);
	
  localparam [39:0] enter_observation = 40'hAxxxxxxxxx;	
	
  wire        		fecc_crcerr;
  wire        		fecc_eccerr;
  wire        		fecc_eccerrsingle;
  wire        		fecc_syndromevalid;
  wire [12:0] 		fecc_syndrome;
  wire [25:0] 		fecc_far;
  wire  [4:0] 		fecc_synbit;
  wire  [6:0] 		fecc_synword;
		
  wire [31:0] 		icap_o;
  wire [31:0] 		icap_i;
  wire        		icap_csib;
  wire        		icap_rdwrb;

  reg 				status_correction_d;
  reg 				status_observation_d;
  
  
  // Delay
  always @(posedge clk_iA or posedge reset_i) begin
	if(reset_i)
	  status_correction_d <= 1'b0;
	else
	  status_correction_d <= status_correction;
  end
  
  // Error counter
  TMR_register_simple #(
        .SIGNAL_WIDTH     (16)
  ) error_counter_TMR (
      .clk_iA             (clk_iA     								),
      .clk_iB             (clk_iB     								),
      .clk_iC             (clk_iC     								),
      .reset_i            (reset_i      							),
  
      .signal_in          (error_counter + 16'b1					),
      .true_condition_i   (status_correction & ~status_correction_d	),
  
      .signal_out         (error_counter  							),
      .detected_seu_o     (error_counter_seu           				)
  );


  // SEM IP
  // Inject interface commands
  // 1100_0000_0000_0000_0000_0000_0000_0000_0001_0011_0011 - inject error
  // 1101_xx.. - diagnostic scan
  // 1111_xx.. - detect only
  // 1010_xx.. - observation state
  // 1110_xx.. - idle state
  // 1011_xx.. - reset
  sem_0 sem_0_inst (
    .status_heartbeat		(status_heartbeat		),
    .status_initialization	(status_initialization	),
    .status_observation		(status_observation		),
    .status_correction		(status_correction		),
    .status_classification	(status_classification	),
    .status_injection		(status_injection		),
    .status_essential		(status_essential		),
    .status_uncorrectable	(status_uncorrectable	),
    
    .monitor_txdata			(						),
    .monitor_txwrite		(						),
    .monitor_txfull			(1'b0					),
    .monitor_rxdata			(8'b0					),
    .monitor_rxread			(						),
    .monitor_rxempty		(1'b1					),
    
    .inject_strobe			(inject_strobe | inject_forced_start					 ),
    .inject_address			(inject_forced_start ? enter_observation : inject_address),
    
    .fecc_crcerr			(fecc_crcerr			),
    .fecc_eccerr			(fecc_eccerr			),
    .fecc_eccerrsingle		(fecc_eccerrsingle		),
    .fecc_syndromevalid		(fecc_syndromevalid		),
    .fecc_syndrome			(fecc_syndrome			),
    .fecc_far				(fecc_far				),
    .fecc_synbit			(fecc_synbit			),
    .fecc_synword			(fecc_synword			),
    .icap_o					(icap_o					),
    .icap_i					(icap_i					),
    .icap_csib				(icap_csib				),
    .icap_rdwrb				(icap_rdwrb				),
    .icap_clk				(clk_iA					),
    .icap_request			(						),
    .icap_grant				(1'b1					)
    );

  // The cfg sub-module contains the device specific primitives to access
  // the internal configuration port and the frame crc/ecc status signals.
  FRAME_ECCE2 #(
    .FRAME_RBT_IN_FILENAME	("NONE"		),
    .FARSRC					("EFAR"		)
  ) frame_ecc_inst (
    .CRCERROR		(fecc_crcerr		),
    .ECCERROR		(fecc_eccerr		),
    .ECCERRORSINGLE	(fecc_eccerrsingle	),
    .FAR			(fecc_far			),
    .SYNBIT			(fecc_synbit		),
    .SYNDROME		(fecc_syndrome		),
    .SYNDROMEVALID	(fecc_syndromevalid	),
    .SYNWORD		(fecc_synword		)
    );

  ICAPE2 #(
    .DEVICE_ID			(32'hFFFFFFFF	),
    .SIM_CFG_FILE_NAME	("NONE"			),
    .ICAP_WIDTH			("X32"			)
  ) icap_inst (
    .O					(icap_o			),
    .CLK				(clk_iA			),
    .CSIB				(icap_csib		),
    .I					(icap_i			),
    .RDWRB				(icap_rdwrb		)
    );

endmodule
