`timescale 1ns / 1ns

module top(
    input  sys_clock,
    
    input  btn_c,
    input  btn_l,   // read  eeprom 
    input  btn_r,   // write eeprom
    input  btn_u,   // push to fifo
    input  btn_d,   // pop from fifo
    
    input  [8-1 : 0] sw,
    output [8-1 : 0] led,
    
    input  rx,
    output tx,
    
    inout sda,
    inout scl
);

    wire reset_i;
    assign reset_i = btn_c;

    
    // Slow clock
    clock_divider #(
        .FREQ_IN    (200_000_000    ),
        .FREQ_OUT   (1              ),
        .MAKE_PULSE (0              )
    ) clock_divider_baud (
        .clk        (sys_clock      ),
        .reset_i    (reset_i        ),
        .clk_o      (slow_clk       )
    );

    
    ///////////////////////////////////////////////////////////////////////// LEDs
    // wire slow_clk;
    
    // always @(posedge sys_clock or posedge reset_i) begin
    //     if(reset_i)
    //         led <= 8'h11;
    //     else if(sw)
    //         led <= slow_clk ? 8'haa : 8'h55;
    //     else
    //         led <= slow_clk ? 8'hf0 : 8'h0f;
    // end
    

    ///////////////////////////////////////////////////////////////////////// UART
    wire [8-1 : 0] data_tx;
    wire [8-1 : 0] data_rx;
    wire send_posedge_i;

    wire read_data;
    reg  read_data_d;
    
    localparam STRING_LENGTH = 15;
    localparam [STRING_LENGTH*8 - 1 : 0] STRING = "_Hello world!\n_";
    reg [8-1 : 0] counter_seq;
    wire pause_tx;
    assign pause_tx = slow_clk;
    
    uart_wrapper #(
        .TP                             (1                              ),
        .PARITY_BIT                     ("none"                         ),  // odd / even / none
        .FREQ                           (100_000_000                    ),
        .BAUD                           (115200                         ),
        .LSB_FIRST                      (0                              ),
        .FIFO_DEPTH                     (64                             )
    ) uart_wrapper_0 (
        .clk                            (sys_clock                      ),
        .reset_i                        (reset_i                        ),
        .rx                             (rx                             ),
        .tx                             (tx                             ),

        .data_i                         (data_tx                        ),
        .send_posedge_i                 (send_posedge_i                 ),
        .is_full_tx                     (is_full_tx                     ),

        .data_o                         (data_rx                        ),
        .read_posedge_i                 (read_posedge_i                 ),
        .is_empty_rx                    (is_empty_rx                    )
    );

    // Premade sequence sender
    always @(posedge sys_clock or posedge reset_i) begin
        if(reset_i)
            counter_seq <= 'b0;
        else if(counter_seq == STRING_LENGTH - 2 & ~is_full_tx)
            counter_seq <= 'b0;
        else if(~is_full_tx | pause_tx)
            counter_seq <= counter_seq + 1;
    end
    
    assign data_tx = STRING[8 * (STRING_LENGTH - 1 - counter_seq) +: 8];
    assign send_posedge_i = (counter_seq > 0) & (~is_full_tx) & (~pause_tx);

    // UART vio
    always @(posedge sys_clock) begin
        read_data_d <= read_data;
    end
    assign read_posedge_i = read_data & (~read_data_d);

    vio_0 uart_vio (
        .clk                (sys_clock        ),
        
        .probe_in0          (data_rx          ),
        .probe_out0         (read_data        ),
        .probe_in1          (is_empty_rx      )
    );


    ///////////////////////////////////////////////////////////////////////// I2C
    localparam ADDR_SIZE = 7;
    wire [ADDR_SIZE-1 : 0] slave_addr_i;
    assign slave_addr_i = 7'b0111011; //b0111011 - b1010111

    wire [8-1 : 0]  data_i;
    wire [8-1 : 0]  data_o;
    assign          data_i[8-1 : 0]          = sw[8-1 : 0];
    assign          led[8-1 : 0]             = data_o[8-1 : 0];

    reg                    start_l_d;
    reg                    start_r_d;
    reg                    start_i;
    reg                    is_read_opp_i;
    reg [8-1 : 0]          byte_amount_i;

    reg                    push_data_d;
    wire                   push_data_i;

    reg                    pop_data_d;
    wire                   pop_data_i;

    i2c_block #(
        .TP                 (1                  ),
        .IN_FREQ            (100_000_000        ),  // 100 MHz
        .OUT_FREQ           (100_000            ),  // 100 KHz
        .ADDR_SIZE          (ADDR_SIZE          ),
        .FIFO_DEPTH         (8                  )
    ) i2c_block_0 (
        .clk                (sys_clock          ),
        .reset_i            (reset_i            ),
        .sda                (sda                ),
        .scl                (scl                ),

        .slave_addr_i       (slave_addr_i       ),  // I2C slave address
        .is_read_opp_i      (is_read_opp_i      ),  // Used to determine whether to read/write to/from slave
        .byte_amount_i      (byte_amount_i      ),  // Used to know how many bytes of data to send/receive
        .start_i            (start_i            ),  // Used to initiate communication
        .ready_o            (ready_o            ),  // Set high if a transaction can be started

        .data_i             (data_i             ),  // Data to be loaded in tx_fifo
        .is_tx_fifo_empty_o (is_tx_fifo_empty_o ),  // Is tx_fifo empty
        .push_data_i        (push_data_i        ),  // Load signal

        .data_o             (data_o             ),  // Data from rx_fifo
        .is_rx_fifo_empty_o (is_rx_fifo_empty_o ),  // Is rx_fifo empty
        .pop_data_i         (pop_data_i         )   // Get data from rx_fifo
    );

    // Edge detectors
    always @(posedge sys_clock) begin
        start_r_d <= btn_r;
    end

    always @(posedge sys_clock) begin
        start_l_d <= btn_l;
    end
    
    always @(posedge sys_clock) begin
        push_data_d <= btn_u;
    end
    assign push_data_i = push_data_d & (~btn_u);

    always @(posedge sys_clock) begin
        pop_data_d <= btn_d;
    end
    assign pop_data_i = pop_data_d & (~btn_d);

    // Start transfer reg
    always @(posedge sys_clock or posedge reset_i) begin
        if(reset_i) begin
            start_i         <= 1'b0;
            is_read_opp_i   <= 1'b0;
            byte_amount_i   <= 8'h00;
        end else if(start_i) begin
            start_i         <= 1'b0;
            is_read_opp_i   <= 1'b0;
            byte_amount_i   <= 8'h00;
        end else if(start_l_d & (~btn_l)) begin // left button - read
            start_i         <= 1'b1;
            is_read_opp_i   <= 1'b1;
            byte_amount_i   <= 8'h01;
        end else if(start_r_d & (~btn_r)) begin // right button - write
            start_i         <= 1'b1;
            is_read_opp_i   <= 1'b0;
            byte_amount_i   <= sw[8-1 : 0];
        end
    end
    
    // I2C vio
    vio_1 i2c_vio (
        .clk        (sys_clock          ),

        .probe_in0  (data_i             ),
        .probe_in1  (is_tx_fifo_empty_o ),

        .probe_in2  (data_o             ),
        .probe_in3  (is_rx_fifo_empty_o )
    );

endmodule