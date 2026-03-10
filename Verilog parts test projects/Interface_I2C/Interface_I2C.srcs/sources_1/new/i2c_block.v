`timescale 1ns / 1ns

module i2c_block #(
    parameter TP            = 1,
    parameter IN_FREQ       = 100_000_000,  // 100 MHz
    parameter OUT_FREQ      = 100_000,      // 100 KHz
    parameter ADDR_SIZE     = 8,
    parameter FIFO_DEPTH    = 8
)(
    input                   clk,
    input                   reset_i,
    inout                   sda,
    inout                   scl,

    input [ADDR_SIZE-1 : 0] slave_addr_i,           // I2C slave address
    input                   is_read_opp_i,          // Used to determine whether to read/write to/from slave
    input [8-1 : 0]         byte_amount_i,          // Used to know how many bytes of data to send/receive
    input                   start_i,                // Used to initiate communication
    output                  ready_o,                // Set high if a transaction can be started

    input [8-1 : 0]         data_i,                 // Data to be loaded in tx_fifo
    output                  is_tx_fifo_empty_o,     // Is tx_fifo empty
    input                   push_data_i,            // Load signal

    output [8-1 : 0]        data_o,                 // Data from rx_fifo
    output                  is_rx_fifo_empty_o,     // Is rx_fifo empty
    input                   pop_data_i              // Get data from rx_fifo
);
    
    // Used if addres width is greater that 8 bits (eg: 10 bits) 
    localparam SH_REG_SIZE = (ADDR_SIZE + 1 > 8) ? (ADDR_SIZE + 1) : 8;

    // Used for pulling ack signal low to emulate a slave device response
    `ifdef SYNTHESIS
        localparam DEBUG = 1;
    `else
        localparam DEBUG = 0;
    `endif
    
    // State machine values
    localparam S_IDLE       = 8'b00000001;
    localparam S_START      = 8'b00000010;
    localparam S_LOAD_ADDR  = 8'b00000100;
    localparam S_ACK_NACK   = 8'b00001000;
    localparam S_LOAD_DATA  = 8'b00010000;
    localparam S_READ_DATA  = 8'b00100000;
    localparam S_STOP       = 8'b01000000;
    localparam S_WAIT       = 8'b10000000;

    // Control signals
    wire                    clk_slow;
    reg                     start_slow;
    reg [7-1 : 0]           state;
    reg [7-1 : 0]           state_d;
    reg [4-1 : 0]           counter;
    reg [4-1 : 0]           aux_counter;
    reg                     is_bus_busy;
    reg                     arbitration;
    assign                  ready_o = (state == S_IDLE);
    
    reg [ADDR_SIZE : 0]     fused_addr;
    reg [8-1 : 0]           byte_amount;
    wire[8-1 : 0]           data_out_tx;

    // Shift registers
    reg [SH_REG_SIZE-1 : 0] shift_reg_tx;
    reg [8-1 : 0]           shift_reg_rx;
    
    // IO buffers signals
    wire                    scl_bit_tx;
    wire                    sda_bit_tx;
    wire                    scl_bit_rx;
    wire                    sda_bit_rx;
    reg                     sda_bit_rx_d;

    // Clock-domain-switching helper signals
    reg                     push_data_rx;
    reg                     push_data_rx_slow;
    reg                     push_data_rx_slow_d;
    reg                     pop_data_tx;
    reg                     pop_data_tx_slow;
    reg                     pop_data_tx_slow_d;


    // IO bi-directional buffers for sda and scl ports
    IOBUF #(
        .DRIVE          (12         ),  // Specify the output drive strength
        .IBUF_LOW_PWR   ("TRUE"     ),  // Low Power - "TRUE", High Performance = "FALSE" 
        .IOSTANDARD     ("DEFAULT"  ),  // Specify the I/O standard
        .SLEW           ("SLOW"     )   // Specify the output slew rate
    ) IOBUF_sda (
        .O              (sda_bit_rx ),  // Buffer output
        .IO             (sda        ),  // Buffer inout port (connect directly to top-level port)
        .I              (1'b0       ),  // Buffer input
        .T              (sda_bit_tx )   // 3-state enable input, high=input, low=output
    );
    
    IOBUF #(
        .DRIVE          (12         ),  // Specify the output drive strength
        .IBUF_LOW_PWR   ("TRUE"     ),  // Low Power - "TRUE", High Performance = "FALSE" 
        .IOSTANDARD     ("DEFAULT"  ),  // Specify the I/O standard
        .SLEW           ("SLOW"     )   // Specify the output slew rate
    ) IOBUF_scl (
        .O              (scl_bit_rx ),  // Buffer output
        .IO             (scl        ),  // Buffer inout port (connect directly to top-level port)
        .I              (1'b0       ),  // Buffer input
        .T              (scl_bit_tx )   // 3-state enable input, high=input, low=output
    );
    
    // Tri-state pin from buffer - hard coded start and stop conditions
    assign scl_bit_tx = ((state == S_START) | (state == S_IDLE)) ? 1'b1 : clk_slow;


    // Clock divider to create I2C frequency
    clock_divider #(
        .FREQ_IN    (IN_FREQ    ),
        .FREQ_OUT   (OUT_FREQ   ),
        .MAKE_PULSE (0          )
    ) clock_divider_0 (
        .clk        (clk        ),
        .reset_i    (reset_i    ),
        .clk_o      (clk_slow   )
    );


////// FAST CLOCK DOMAIN

    // Input and output FIFO's
    fifo #(
        .DATA_WIDTH     (8                  ),
        .DEPTH          (FIFO_DEPTH         )
    ) tx_fifo (
        .clk            (clk                ),
        .rst_n          (~reset_i           ),

        .write_enable   (push_data_i        ),
        .data_i         (data_i             ),

        .read_enable    (pop_data_tx        ),
        .data_o         (data_out_tx        ),

        .full           (                   ),
        .empty          (is_tx_fifo_empty_o )
    );
    
    fifo #(
        .DATA_WIDTH     (8                  ),
        .DEPTH          (FIFO_DEPTH         )
    ) rx_fifo (
        .clk            (clk                ),
        .rst_n          (~reset_i           ),

        .write_enable   (push_data_rx       ),
        .data_i         (shift_reg_rx       ),

        .read_enable    (pop_data_i         ),
        .data_o         (data_o             ),

        .full           (                   ),
        .empty          (is_rx_fifo_empty_o )
    );
    
    
    // Read register to get address and is_read_opp_i
    always @(posedge clk or posedge reset_i) begin
		if(reset_i)
			fused_addr <= #TP {(ADDR_SIZE+1){1'b0}};
		else if(start_i & ready_o)
			fused_addr <= #TP {slave_addr_i, is_read_opp_i};
    end


    // Read register to get byte_amount
    always @(posedge clk or posedge reset_i) begin
		if(reset_i)
			byte_amount <= #TP {8{1'b0}};
		else if(start_i & ready_o)
			byte_amount <= #TP byte_amount_i;
    end
    
    
    // Checks if bus is being used
    always @(posedge clk) begin
        sda_bit_rx_d <= #TP sda_bit_rx;
    end
    
    always @(posedge clk or posedge reset_i) begin
		if(reset_i)
			is_bus_busy <= #TP 1'b0;
		else if(scl_bit_rx & (~sda_bit_rx & sda_bit_rx_d))                  // Start condition on bus
			is_bus_busy <= #TP 1'b1;
		else if(is_bus_busy & scl_bit_rx & (sda_bit_rx & ~sda_bit_rx_d))    // End condition on bus
			is_bus_busy <= #TP 1'b0;
    end


    // Makes start_i last until it is detected
    always @(posedge clk or posedge reset_i) begin
		if(reset_i)
			start_slow <= #TP 1'b0;
        else if(state == S_START)
			start_slow <= #TP 1'b0;
		else if(start_i)
			start_slow <= #TP 1'b1;
    end
    

    // Used to jump clock domains - implements posedge detector for push_data_rx 
    always @(posedge clk) begin
        push_data_rx_slow_d <= #TP push_data_rx_slow;
    end

    always @(posedge clk or posedge reset_i) begin
		if(reset_i)
			push_data_rx <= #TP 1'b0;
        else if(push_data_rx)
			push_data_rx <= #TP 1'b0;
		else if(push_data_rx_slow & (~push_data_rx_slow_d))
			push_data_rx <= #TP 1'b1;
    end

    // Used to jump clock domains - implements posedge detector for pop_data_tx
    always @(posedge clk) begin
        pop_data_tx_slow_d <= #TP pop_data_tx_slow;
    end

    always @(posedge clk or posedge reset_i) begin
		if(reset_i)
			pop_data_tx <= #TP 1'b0;
        else if(pop_data_tx)
			pop_data_tx <= #TP 1'b0;
		else if(pop_data_tx_slow & (~pop_data_tx_slow_d) & (aux_counter < byte_amount))
			pop_data_tx <= #TP 1'b1;
    end


//////SLOW CLOCK DOMAIN

    // Signal to store data read from sda - push_data_rx_slow
    always @(negedge clk_slow or posedge reset_i) begin
		if(reset_i)
			push_data_rx_slow <= #TP 1'b0;
        else if(push_data_rx_slow)
			push_data_rx_slow <= #TP 1'b0;
		else if((state == S_READ_DATA) & (counter == 7))
			push_data_rx_slow <= #TP 1'b1;
    end

    // Signal to get data from tx_fifo - pop_data_tx_slow
    always @(negedge clk_slow or posedge reset_i) begin
		if(reset_i)
			pop_data_tx_slow <= #TP 1'b0;
        else if(pop_data_tx_slow)
			pop_data_tx_slow <= #TP 1'b0;
		else if((state == S_START) | (state_d == S_ACK_NACK))
			pop_data_tx_slow <= #TP 1'b1;
    end


    // SDA transmit shift register
    always @(negedge clk_slow or posedge reset_i) begin
		if(reset_i)
			shift_reg_tx <= #TP {SH_REG_SIZE{1'b1}};

        // Resets shift register after stop condition to clear sda line
		else if(state == S_STOP)    
			shift_reg_tx <= #TP {SH_REG_SIZE{1'b1}};

        // Loads addr and RW bit
		else if(state == S_START)   
			shift_reg_tx <= #TP {fused_addr, {(SH_REG_SIZE - ADDR_SIZE - 1){1'b1}}}; 

        // Loads data from fifo
		else if(((state == S_ACK_NACK) & (state_d == S_LOAD_ADDR) & (~shift_reg_rx[1])) |
                ((state == S_ACK_NACK) & (state_d == S_LOAD_DATA)))  
			shift_reg_tx <= #TP {data_out_tx, {(SH_REG_SIZE - 8){1'b1}}};

		else
			shift_reg_tx <= #TP {shift_reg_tx[SH_REG_SIZE-2 : 0], 1'b1};
    end

    // Tri-state pin from buffer - sometimes overrides the shift_reg_tx assignation
    assign sda_bit_tx = ((state == S_START) | (state == S_STOP) |                                           // Hard coded start and stop condition
                         ((state == S_ACK_NACK) & (state_d == S_READ_DATA) & (aux_counter != byte_amount))) // Hard coded ack signal 
                        ? 1'b0 : shift_reg_tx[SH_REG_SIZE - 1];


    // SDA receive shift register
    // ALWAYS READ ON POSEDGE SIGNAL
    always @(posedge clk_slow or posedge reset_i) begin
		if(reset_i)
			shift_reg_rx <= #TP {8{1'b1}};
		else
			shift_reg_rx <= #TP {shift_reg_rx[6 : 0], sda_bit_rx};
    end
    
    
    // Check arbitration
    always @(posedge clk_slow or posedge reset_i) begin
		if(reset_i)
		   arbitration <= #TP 1'b0;
        else if(~is_bus_busy)
           arbitration <= #TP 1'b0;
        else if(~arbitration)
           arbitration <= #TP (sda_bit_rx ^ sda_bit_tx) & (state != S_ACK_NACK);
    end


    // State machine
    always @(negedge clk_slow or posedge reset_i) begin
		if(reset_i)
			state <= #TP S_IDLE;
			
	   // Interrupt if lost arbitration
	   else if(arbitration)
			state <= #TP S_WAIT;
			
	    // Start condition
		else if(start_slow & ready_o) begin
		    if(is_bus_busy)
		        state <= #TP S_WAIT;
		    else
		        state <= #TP S_START;
		end

        // Start transfer again when line isn't busy anymore
        else if((state == S_WAIT) & ~is_bus_busy)
			state <= #TP S_START;
        
        // After start loads the slave address and is_read_opp_i
		else if(state == S_START)
			state <= #TP S_LOAD_ADDR;

        // After each data transfer, wait/send ack/nack signal
        else if(((state == S_LOAD_ADDR) & (counter == ADDR_SIZE)) |
                ((state == S_LOAD_DATA) & (counter == 7)) |
                ((state == S_READ_DATA) & (counter == 7)))
            state <= #TP S_ACK_NACK;

        // Choose what to do after receiving ack/nack signal
        else if(state == S_ACK_NACK) begin
            // If received nack - initiate stop condition
            if(shift_reg_rx[0] & DEBUG)    
			    state <= #TP S_STOP;

            // If previous state is S_LOAD_ADDR, choose to send or received data based on is_read_opp_i
            else if(state_d == S_LOAD_ADDR)
                state <= #TP (shift_reg_rx[1]) ? S_READ_DATA : S_LOAD_DATA;

            // If previous state is S_READ_DATA, choose to keep reading or stop based on byte_amount
            else if(state_d == S_READ_DATA)
                state <= #TP (aux_counter == byte_amount) ? S_STOP : S_READ_DATA;

            // If previous state is S_LOAD_ADDR, choose to keep sending or stop based on byte_amount
            else if(state_d == S_LOAD_DATA)
                state <= #TP (aux_counter == byte_amount) ? S_STOP : S_LOAD_DATA;

            // If the state machine is broken - hard exit    
            else
                state <= S_STOP;
        end

        // Stop condition
        else if(state == S_STOP)
            state <= #TP S_IDLE;
    end
    
    // Delayed state
    always @(negedge clk_slow) begin
        state_d <=  #TP state;
    end


    // Counter used to keep count of how many bits were sent/received
    always @(negedge clk_slow or posedge reset_i) begin
		if(reset_i)
			counter <= #TP {4{1'b0}};
		else if((state == S_IDLE) | (state == S_START) | (state == S_ACK_NACK))
			counter <= #TP {4{1'b0}};
		else
			counter <= #TP counter + 1;
    end

    // Auxiliary counter used to keep count of how many bytes were sent/received
    // Increments when a byte has been written/read
    always @(negedge clk_slow or posedge reset_i) begin
		if(reset_i)
			aux_counter <= #TP {4{1'b0}};
		else if(state == S_IDLE)
			aux_counter <= #TP {4{1'b0}};
		else if(((state == S_READ_DATA) & (state_d != S_READ_DATA)) |
                ((state == S_LOAD_DATA) & (state_d != S_LOAD_DATA)))
			aux_counter <= #TP aux_counter + 1;
    end
    
endmodule
