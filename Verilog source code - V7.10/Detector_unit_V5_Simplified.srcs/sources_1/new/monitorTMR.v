`timescale 1ns / 1ns

module monitorTMR #(
    parameter TP          = 1,
    parameter ADDR_WIDTH  = 9,
    parameter DATA_WIDTH  = 72
)(
    input                           clk_iA,
    input                           clk_iB,
    input                           clk_iC,
    input                           reset_i,
    input [ADDR_WIDTH-1:0]          addr_i,  
    input                           addr_valid_i,
    input [DATA_WIDTH-1:0]          read_data_i,  

    output [ADDR_WIDTH-1:0]         addr_o,  
    output [DATA_WIDTH-1:0]         wr_data_o,  
    output                          wr_en_o,
    output [ADDR_WIDTH-1:0]         bram_seu_addr_o,  
    output [DATA_WIDTH-1:0]         bram_seu_bitmap_o,  
    output                          bram_seu_valid_o,
    output                          seu_o,
    output                          busy_o              
);

wire [ADDR_WIDTH-1:0]    addr_del_1;
wire                     addr_del_1_seu;
wire                     addr_valid_del_1;
wire                     addr_valid_del_1_seu;
wire [ADDR_WIDTH-1:0]    addr_del_2;
wire                     addr_del_2_seu;
wire                     addr_valid_del_2;
wire                     addr_valid_del_2_seu;


wire [DATA_WIDTH-1:0]         flips_bitmap_index;
wire                          flips_bitmap_index_seu;
wire                          any_flips;
wire                          any_flips_bitmap_index_seu;      
wire [ADDR_WIDTH-1:0]         addr_out;
wire                          addr_out_seu;
wire                          busy;
wire                          busy_seu;     

wire [71:0] odd_address_pattern;
wire [71:0] even_address_pattern;  
assign  odd_address_pattern     = 72'hAAAAAAAAAAAAAAAAAA;
assign  even_address_pattern    = 72'h555555555555555555;

wire [DATA_WIDTH-1:0]         xor_array;
wire                          any_bit_error;

assign xor_array = read_data_i ^ (addr_del_2[0] ? odd_address_pattern[DATA_WIDTH - 1:0] : even_address_pattern[DATA_WIDTH - 1:0]);
assign any_bit_error = |xor_array;


// addr_del_1
TMR_register_simple #(
    .SIGNAL_WIDTH       (ADDR_WIDTH)
) addr_del_1_TMR (
    .clk_iA             (clk_iA),
    .clk_iB             (clk_iB),
    .clk_iC             (clk_iC),
    .reset_i            (reset_i),

    .signal_in          (addr_i),
    .true_condition_i   (addr_valid_i),

    .signal_out         (addr_del_1),
    .detected_seu_o     (addr_del_1_seu)
);

// addr_valid_del_1
TMR_register_simple #(
    .SIGNAL_WIDTH       (1)
) addr_valid_del_1_TMR (
    .clk_iA             (clk_iA),
    .clk_iB             (clk_iB),
    .clk_iC             (clk_iC),
    .reset_i            (reset_i),

    .signal_in          (addr_valid_i),
    .true_condition_i   (1'b1),

    .signal_out         (addr_valid_del_1),
    .detected_seu_o     (addr_valid_del_1_seu)
);

// addr_del_2
TMR_register_simple #(
    .SIGNAL_WIDTH       (ADDR_WIDTH)
) addr_del_2_TMR (
    .clk_iA             (clk_iA),
    .clk_iB             (clk_iB),
    .clk_iC             (clk_iC),
    .reset_i            (reset_i),

    .signal_in          (addr_del_1),
    .true_condition_i   (addr_valid_del_1),

    .signal_out         (addr_del_2),
    .detected_seu_o     (addr_del_2_seu)
);

// addr_valid_del_2
TMR_register_simple #(
    .SIGNAL_WIDTH       (1)
) addr_valid_del_2_TMR (
    .clk_iA             (clk_iA),
    .clk_iB             (clk_iB),
    .clk_iC             (clk_iC),
    .reset_i            (reset_i),

    .signal_in          (addr_valid_del_1),
    .true_condition_i   (1'b1),

    .signal_out         (addr_valid_del_2),
    .detected_seu_o     (addr_valid_del_2_seu)
);

// flips_bitmap_index
TMR_register_simple #(
    .SIGNAL_WIDTH       (DATA_WIDTH)
) flips_bitmap_index_TMR (
    .clk_iA             (clk_iA),
    .clk_iB             (clk_iB),
    .clk_iC             (clk_iC),
    .reset_i            (reset_i),

    .signal_in          (xor_array),
    .true_condition_i   (addr_valid_del_2),

    .signal_out         (flips_bitmap_index),
    .detected_seu_o     (flips_bitmap_index_seu)
);

// any_flips
TMR_register_simple #(
    .SIGNAL_WIDTH       (1)
) any_flips_TMR (
    .clk_iA             (clk_iA),
    .clk_iB             (clk_iB),
    .clk_iC             (clk_iC),
    .reset_i            (reset_i),

    .signal_in          (any_bit_error),
    .true_condition_i   (addr_valid_del_2),

    .signal_out         (any_flips),
    .detected_seu_o     (any_flips_bitmap_index_seu)
);

// addr_out
TMR_register_simple #(
    .SIGNAL_WIDTH       (ADDR_WIDTH)
) addr_out_TMR (
    .clk_iA             (clk_iA),
    .clk_iB             (clk_iB),
    .clk_iC             (clk_iC),
    .reset_i            (reset_i),

    .signal_in          (addr_del_2),
    .true_condition_i   (addr_valid_del_2 & any_bit_error),

    .signal_out         (addr_out),
    .detected_seu_o     (addr_out_seu)
);

// busy
TMR_register_simple #(
    .SIGNAL_WIDTH       (1)
) busy_TMR (
    .clk_iA             (clk_iA),
    .clk_iB             (clk_iB),
    .clk_iC             (clk_iC),
    .reset_i            (reset_i),

    .signal_in          (addr_valid_i | addr_valid_del_2),
    .true_condition_i   (1'b1),

    .signal_out         (busy),
    .detected_seu_o     (busy_seu)
);


assign addr_o               = addr_out;
assign wr_data_o            = addr_o[0] ? odd_address_pattern[DATA_WIDTH - 1:0] : even_address_pattern[DATA_WIDTH - 1:0];
assign wr_en_o              = any_flips;
assign bram_seu_addr_o      = addr_out;
assign bram_seu_bitmap_o    = ~flips_bitmap_index;
assign bram_seu_valid_o     = any_flips;
assign busy_o               = busy;
assign seu_o                = addr_del_1_seu | addr_valid_del_1_seu | addr_del_2_seu | addr_valid_del_2_seu | flips_bitmap_index_seu | any_flips_bitmap_index_seu | addr_out_seu | busy_seu;

endmodule
