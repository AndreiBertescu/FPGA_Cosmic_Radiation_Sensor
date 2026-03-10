`timescale 1ns / 1ns

module uart_wrapper #(
    parameter TP            = 1,
    parameter PARITY_BIT    = "even",  // odd / even / none
    parameter FREQ          = 100_000_000,  // 100 MHz
    parameter BAUD          = 9600,
    parameter LSB_FIRST     = 1,
    parameter FIFO_DEPTH    = 8
)(
    input               clk,
    input               reset_i,
    input               rx,
    output              tx,

    input [8-1 : 0]     data_i,
    input               send_posedge_i,
    output              is_full_tx,
    
    output [8-1 : 0]    data_o,
    input               read_posedge_i,
    output              is_empty_rx
);

    // tx signals
    wire [8-1 : 0]  data_tx;
    reg             send_data_posedge;
    reg             send_data_posedge_d;
    wire            clear_to_send;
    wire            is_empty_tx;

    //rx signals
    wire [8-1 : 0]  data_rx;
    wire            received_data_posedge;
    wire            received_data_parity_error;


    // uart
    if(PARITY_BIT == "none") begin
        uart_block_no_parity #(
            .TP                             (TP                         ),
            .FREQ                           (FREQ                       ),
            .BAUD                           (BAUD                       ),
            .LSB_FIRST                      (LSB_FIRST                  )
        ) uart_block_0 (
            .clk                            (clk                        ),
            .reset_i                        (reset_i                    ),
            .rx                             (rx                         ),
            .tx                             (tx                         ),

            .data_tx_i                      (data_tx                    ),
            .send_data_posedge_i            (send_data_posedge          ),
            .clear_to_send_o                (clear_to_send              ),

            .data_rx_o                      (data_rx                    ),
            .received_data_posedge_o        (received_data_posedge      )
        );

        assign received_data_parity_error = 1'b0;
    end else begin
        uart_block #(
            .TP                             (TP                         ),
            .PARITY_BIT                     (PARITY_BIT                 ),  // odd / even
            .FREQ                           (FREQ                       ),
            .BAUD                           (BAUD                       ),
            .LSB_FIRST                      (LSB_FIRST                  )
        ) uart_block_0 (
            .clk                            (clk                        ),
            .reset_i                        (reset_i                    ),
            .rx                             (rx                         ),
            .tx                             (tx                         ),

            .data_tx_i                      (data_tx                    ),
            .send_data_posedge_i            (send_data_posedge          ),
            .clear_to_send_o                (clear_to_send              ),

            .data_rx_o                      (data_rx                    ),
            .received_data_posedge_o        (received_data_posedge      ),
            .received_data_parity_error_o   (received_data_parity_error )
        );
    end


    // tx fifo
    fifo #(
        .DATA_WIDTH     (8),
        .DEPTH          (FIFO_DEPTH)
    ) tx_fifo (
        .clk            (clk),
        .rst_n          (~reset_i),

        .write_enable   (send_posedge_i),
        .data_i         (data_i),

        .read_enable    (send_data_posedge),
        .data_o         (data_tx),

        .full           (is_full_tx),
        .empty          (is_empty_tx)
    );

    // delay FF
    always @(posedge clk) begin
        send_data_posedge_d <= send_data_posedge;
    end

    always @(posedge clk or posedge reset_i) begin
		if(reset_i)
			send_data_posedge <= #TP 1'b0;
		else if(send_data_posedge)
			send_data_posedge <= #TP 1'b0;
		else if(~is_empty_tx & clear_to_send & ~send_data_posedge_d)
			send_data_posedge <= #TP 1'b1;
    end


    // rx fifo
    fifo #(
        .DATA_WIDTH     (8),
        .DEPTH          (FIFO_DEPTH)
    ) rx_fifo (
        .clk            (clk),
        .rst_n          (~reset_i),

        .write_enable   (received_data_posedge & ~received_data_parity_error),
        .data_i         (data_rx),

        .read_enable    (read_posedge_i),
        .data_o         (data_o),

        .full           (),
        .empty          (is_empty_rx)
    );

endmodule
