`timescale 1ns / 1ns

module uart_block_tb();

localparam HALF_100_MHZ_CLOCK_PERIOD = 5; //half of the period of the 100 MHz clock
localparam TP = 1;

reg     clk;
reg     reset_i;
wire    rx;
wire    tx;
assign  rx = tx;

reg[8-1 : 0]    data_tx_i;
reg             send_data_posedge_i;
wire            clear_to_send_o;

wire[8-1 : 0]   data_rx_o;
wire            received_data_posedge_o;
wire            received_data_parity_error_o;


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
    data_tx_i = 0;
    send_data_posedge_i = 0;

    // Wait reset
    repeat (10) @(posedge clk);
    reset_i = 0;

    // Set data
    data_tx_i = #TP 'h6b;
    repeat (3) @(posedge clk);

    // Send data
    send_data_posedge_i = #TP 1;
    @(posedge clk);
    send_data_posedge_i = #TP 0;

    // Wait send to finish
    @(posedge clear_to_send_o);

    // Set data
    data_tx_i = #TP 'ha5;
    repeat (3) @(posedge clk);

    // Send data
    send_data_posedge_i = #TP 1;
    @(posedge clk);
    send_data_posedge_i = #TP 0;
    
    // Wait send to finish
    @(posedge clear_to_send_o);

    repeat (10000) @(posedge clk);
    $finish;
end


//// DUV
//uart_block #(
//    .TP                             (TP                             ),
//    .PARITY_BIT                     ("odd"                          ),  // odd / even
//    .FREQ                           (100_000_000                    ),
//    .BAUD                           (115200                         ),
//    .LSB_FIRST                      (0                              )
//) DUV (
//    .clk                            (clk                            ),
//    .reset_i                        (reset_i                        ),
//    .rx                             (rx                             ),
//    .tx                             (tx                             ),

//    .data_tx_i                      (data_tx_i                      ),
//    .send_data_posedge_i            (send_data_posedge_i            ),
//    .clear_to_send_o                (clear_to_send_o                ),

//    .data_rx_o                      (data_rx_o                      ),
//    .received_data_posedge_o        (received_data_posedge_o        ),
//    .received_data_parity_error_o   (received_data_parity_error_o   )
//);

// DUV 2
uart_block_no_parity #(
    .TP                             (TP                             ),
    .FREQ                           (100_000_000                    ),
    .BAUD                           (115200                         ),
    .LSB_FIRST                      (0                              )
) DUV_2 (
    .clk                            (clk                            ),
    .reset_i                        (reset_i                        ),
    .rx                             (rx                             ),
    .tx                             (tx                             ),

    .data_tx_i                      (data_tx_i                      ),
    .send_data_posedge_i            (send_data_posedge_i            ),
    .clear_to_send_o                (clear_to_send_o                ),

    .data_rx_o                      (data_rx_o                      ),
    .received_data_posedge_o        (received_data_posedge_o        )
);

endmodule
