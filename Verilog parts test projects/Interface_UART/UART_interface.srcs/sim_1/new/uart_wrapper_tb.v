`timescale 1ns / 1ns

module uart_wrapper_tb();

localparam HALF_100_MHZ_CLOCK_PERIOD = 5; //half of the period of the 100 MHz clock
localparam TP = 1;

reg     clk;
reg     reset_i;
wire    rx;
wire    tx;
assign  rx = tx;

reg[8-1 : 0]    data_i;
reg             send_posedge_i;
wire            is_full_tx;

wire[8-1 : 0]   data_o;
reg             read_posedge_i;
wire            is_empty_rx;


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
    data_i = 0;
    send_posedge_i = 0;
    read_posedge_i = 0;

    // Wait reset
    repeat (10) @(posedge clk);
    reset_i = 0;

    // Send data
    data_i <= #TP 'haa;
    send_posedge_i <= #TP 1;
    @(posedge clk);
    data_i = #TP 'h00;
    send_posedge_i = #TP 0;
    @(posedge clk);

    // Send data
    data_i <= #TP 'h6b;
    send_posedge_i <= #TP 1;
    @(posedge clk);
    data_i = #TP 'h00;
    send_posedge_i = #TP 0;
    @(posedge clk);

    // Send data
    data_i <= #TP 'h55;
    send_posedge_i <= #TP 1;
    @(posedge clk);
    data_i = #TP 'h00;
    send_posedge_i = #TP 0;
    @(posedge clk);

    // Send data
    data_i <= #TP 'hf1;
    send_posedge_i <= #TP 1;
    @(posedge clk);
    data_i = #TP 'h00;
    send_posedge_i = #TP 0;
    @(posedge clk);

    // Wait for receive
    @(negedge is_empty_rx);
    read_posedge_i = #TP 1;
    @(posedge clk);
    read_posedge_i = #TP 0;
    
    @(negedge is_empty_rx);
    read_posedge_i = #TP 1;
    @(posedge clk);
    read_posedge_i = #TP 0;
    
    @(negedge is_empty_rx);
    read_posedge_i = #TP 1;
    @(posedge clk);
    read_posedge_i = #TP 0;

    @(negedge is_empty_rx);
    read_posedge_i = #TP 1;
    @(posedge clk);
    read_posedge_i = #TP 0;

    repeat (10000) @(posedge clk);
    $finish;
end


// DUV
uart_wrapper #(
    .TP                             (TP                             ),
    .PARITY_BIT                     ("odd"                          ),  // odd / even
    .FREQ                           (100_000_000                    ),
    .BAUD                           (115200                         ),
    .LSB_FIRST                      (0                              ),
    .FIFO_DEPTH                     (8                              )
) DUV (
    .clk                            (clk                            ),
    .reset_i                        (reset_i                        ),
    .rx                             (rx                             ),
    .tx                             (tx                             ),

    .data_i                         (data_i                         ),
    .send_posedge_i                 (send_posedge_i                 ),
    .is_full_tx                     (is_full_tx                     ),

    .data_o                         (data_o                         ),
    .read_posedge_i                 (read_posedge_i                 ),
    .is_empty_rx                    (is_empty_rx                    )
);

endmodule
