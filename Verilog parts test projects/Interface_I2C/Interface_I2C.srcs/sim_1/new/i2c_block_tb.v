`timescale 1ns / 1ns

module i2c_block_tb();

    localparam HALF_100_MHZ_CLOCK_PERIOD    = 5; //half of the period of the 100 MHz clock
    localparam TP                           = 1;
    localparam ADDR_SIZE                    = 7;

    reg                   clk;
    reg                   reset_i;
    wire                  sda;
    wire                  scl;
    pullup(sda);
    pullup(scl);

    reg [ADDR_SIZE-1 : 0] slave_addr_i;       // I2C slave address
    reg                   is_read_opp_i;      // Used to determine whether to read/write to/from slave
    reg [8-1 : 0]         byte_amount_i;      // Used to know how many bytes of data to send/receive
    reg                   start_i;            // Used to initiate communication
    wire                  ready_o;            // Set high if a transaction can be started

    reg [8-1 : 0]         data_i;             // Data to be loaded in tx_fifo
    wire                  is_tx_fifo_empty_o; // Is tx_fifo empty
    reg                   push_data_i;        // Load signal

    wire [8-1 : 0]        data_o;             // Data from rx_fifo
    wire                  is_rx_fifo_empty_o; // Is rx_fifo empty
    reg                   pop_data_i;         // Get data from rx_fifo


    // Clock generator
    initial begin
        clk <= 1'b0;
        forever begin
            #HALF_100_MHZ_CLOCK_PERIOD clk <= ~clk;
        end
    end
    

    // Main test loop
    initial begin
        slave_addr_i    = 0;
        is_read_opp_i   = 0;
        byte_amount_i   = 0;
        start_i         = 0;
        data_i          = 0;
        push_data_i     = 0;
        pop_data_i      = 0;

        // Wait reset
        reset_i = 0;
        @(posedge clk);
        reset_i = 1;
        repeat (10) @(posedge clk);
        reset_i = 0;

        // Load data to fifo
        push_data_i = #TP 1;

        data_i = 'h6b;
        @(posedge clk);

        data_i = #TP 'h3f;
        @(posedge clk);
        
//        data_i = #TP 'ha5;
//        @(posedge clk);

        push_data_i = #TP 0;

        // Set other parameters
        slave_addr_i    = 'b1010111;
        is_read_opp_i   = 0;
        byte_amount_i   = 2;

        // Start data transfer
        start_i = #TP 1;
        @(posedge clk);
        start_i = #TP 0;

        // Wait send to finish
        @(posedge ready_o);
        
        repeat (1000) @(posedge clk);
        $finish;
    end


    // DUV
    i2c_block #(
        .TP                 (TP                 ),
        .IN_FREQ            (100_000_000        ),  // 100 MHz
        .OUT_FREQ           (100_000            ),  // 100 KHz
        .ADDR_SIZE          (ADDR_SIZE          ),
        .FIFO_DEPTH         (8                  )
    ) DUV (
        .clk                (clk                ),
        .reset_i            (reset_i            ),
        .sda                (sda                ),
        .scl                (scl                ),

        .slave_addr_i       (slave_addr_i       ),  // I2C slave address
        .is_read_opp_i      (is_read_opp_i      ),  // Used to determine whether to read/write to/from slave
        .byte_amount_i      (byte_amount_i      ),  // Used to know how many bytes of data to send/receive
        .start_i            (start_i            ),  // Used to initiate communication
        .ready_o            (ready_o            ),  // Set high if a transaction can be started

        .data_i             (data_i             ),  // Data to be loaded in tx_fifo
        .is_tx_fifo_empty_o (is_tx_fifo_empty_o ),  // Is rx_fifo empty
        .push_data_i        (push_data_i        ),  // Load signal

        .data_o             (data_o             ),  // Data from rx_fifo
        .is_rx_fifo_empty_o (is_rx_fifo_empty_o ),  // Is rx_fifo empty
        .pop_data_i         (pop_data_i         )   // Get data from rx_fifo
    );

endmodule
