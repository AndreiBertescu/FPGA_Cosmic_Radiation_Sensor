`timescale 1ns / 1ps

module BRAM_SEU_detector #(
  parameter TP              = 1,
  parameter INDEX           = 0,
  parameter ADDR_WIDTH      = 9,
  parameter DATA_WIDTH      = 72,
  parameter USE_LUTRAM      = 0
)(
  input                             clk_iA,
  input                             clk_iB,
  input                             clk_iC,
  input                             reset_i,
  input                             start_i,

  output [ADDR_WIDTH-1:0]           bram_seu_addr_o,
  output [DATA_WIDTH-1:0]           bram_seu_bitmap_o,
  output                            bram_seu_valid_o,
  output                            logic_seu_o,
  output                            busy_o,
  input                             reset_prot_cntr_i,

  input [ADDR_WIDTH-1:0]            inj_err_address_i,
  input [DATA_WIDTH-1:0]            inj_err_data_i,
  input                             inj_err_valid_i
);

localparam [8-1 : 0] PROTECTION_COUNTER_SIZE = 8'd16;

wire                  clk;
wire                  wea;
wire [ADDR_WIDTH-1:0] wr_addr;
wire [DATA_WIDTH-1:0] wr_data;

wire [ADDR_WIDTH-1:0] addr_value;
wire                  addr_value_valid;
wire                  counter_seu;
wire [DATA_WIDTH-1:0] read_data;
wire [ADDR_WIDTH-1:0] write_addr;
wire [DATA_WIDTH-1:0] write_data;
wire                  write_enable;
wire                  monitor_seu;

wire [8-1 : 0]        protection_counter;
wire                  protections_counter_seu;
wire                  bram_seu_valid;

wire   total_seu_maj_voted;
wire   total_seu_maj_voted_seu;
assign logic_seu_o = total_seu_maj_voted | total_seu_maj_voted_seu;

assign clk      = ((INDEX % 3) == 0) ? clk_iA : (((INDEX % 3) == 1) ? clk_iB : clk_iC);

`ifdef SYNTHESIS
    assign wea      = write_enable;
    assign wr_addr  = write_addr;
    assign wr_data  = write_data;
`else
    assign wea      = busy_o ? write_enable : inj_err_valid_i;
    assign wr_addr  = busy_o ? write_addr   : inj_err_address_i;
    assign wr_data  = busy_o ? write_data   : inj_err_data_i;
`endif


// total_seu_maj_voted
TMR_register_simple #(
    .SIGNAL_WIDTH       (1)
) total_seu_maj_voted_TMR (
    .clk_iA             (clk_iA),
    .clk_iB             (clk_iB),
    .clk_iC             (clk_iC),
    .reset_i            (reset_i),

    .signal_in          (counter_seu | monitor_seu | protections_counter_seu),
    .true_condition_i   (1'b1),

    .signal_out         (total_seu_maj_voted),
    .detected_seu_o     (total_seu_maj_voted_seu)
);


// Address counter
counterTMR #(
    .TP       (TP               ),
    .WIDTH    (ADDR_WIDTH       )
) ADDR_COUNTER (
    .clk_iA   (clk_iA           ),
    .clk_iB   (clk_iB           ),
    .clk_iC   (clk_iC           ),
    .reset_i  (reset_i          ),
    .start_i  (start_i          ),
    .value_o  (addr_value       ), //9-bit
    .valid_o  (addr_value_valid ),
    .seu_o    (counter_seu      )
);


// Main detector memory
if(~USE_LUTRAM) begin
    blk_mem_gen_2 BRAM_MEMORY (
        .clka   (clk          ),
        .wea    (wea          ),
        .addra  (wr_addr      ),
        .dina   (wr_data      ),
        .clkb   (clk          ),
        .addrb  (addr_value   ),
        .doutb  (read_data    )
    );
end else begin
    lut_ram #(
        .WIDTH	(DATA_WIDTH			),
        .DEPTH	(1<<ADDR_WIDTH		),
        .INIT_A	(18'h15555			),
        .INIT_B	(18'h2AAAA			)
    ) LUTRAM_MEMORY (		
        .clka   (clk				),
                
        .wea    (wea				),
        .addra  (wr_addr			),
        .dina   (wr_data			),
        
        .addrb  (addr_value			),
        .doutb  (read_data	        )
    );
end

// SEU detector
monitorTMR #(
    .TP                 (TP                 ),
    .ADDR_WIDTH         (ADDR_WIDTH         ),
    .DATA_WIDTH         (DATA_WIDTH         )
) MONITOR (
    .clk_iA             (clk_iA             ),
    .clk_iB             (clk_iB             ),
    .clk_iC             (clk_iC             ),
    .reset_i            (reset_i            ),
    .addr_i             (addr_value         ), //9-bit
    .addr_valid_i       (addr_value_valid   ),
    .read_data_i        (read_data          ), //72-bit
    .addr_o             (write_addr         ), //9-bit
    .wr_data_o          (write_data         ), //72-bit
    .wr_en_o            (write_enable       ),
    .bram_seu_addr_o    (bram_seu_addr_o    ), //9-bit
    .bram_seu_bitmap_o  (bram_seu_bitmap_o  ), //72-bit
    .bram_seu_valid_o   (bram_seu_valid     ),
    .seu_o              (monitor_seu        ),
    .busy_o             (busy_o             )
);


// Too many SEUs protection counter
TMR_register #(
    .SIGNAL_WIDTH       (8                          )
) protection_counter_TMR (
    .clk_iA             (clk_iA                     ),
    .clk_iB             (clk_iB                     ),
    .clk_iC             (clk_iC                     ),
    .reset_i            (reset_i                    ),

    .reset_condition_i  (reset_prot_cntr_i          ),
    .signal_in          (protection_counter + 8'b1  ),
    .true_condition_i   (bram_seu_valid             ),

    .signal_out         (protection_counter         ),
    .detected_seu_o     (protections_counter_seu    )
);

assign bram_seu_valid_o = bram_seu_valid & (protection_counter < PROTECTION_COUNTER_SIZE);

endmodule
