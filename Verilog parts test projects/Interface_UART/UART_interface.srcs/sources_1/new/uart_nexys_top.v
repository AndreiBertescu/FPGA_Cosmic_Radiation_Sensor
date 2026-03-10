`timescale 1ns / 1ns

module uart_nexys_top(
    input  sys_clock,
    input  reset_i,

    input  rx,
    output tx
);

    wire [8-1 : 0]  data_tx_i;
    wire            send_data_posedge_i;
    wire            clear_to_send_o;
    wire [8-1 : 0]  data_rx_o;


    // DUV
    uart_block #(
        .TP                             (1                      ),
        .PARITY_BIT                     ("odd"                  ),  // odd / even
        .FREQ                           (100_000_000            ),
        .BAUD                           (115200                 ),
        .LSB_FIRST                      (0                      )
    ) DUV (
        .clk                            (sys_clock              ),
        .reset_i                        (reset_i                ),
        .rx                             (rx                     ),
        .tx                             (tx                     ),

        .data_tx_i                      (data_tx_i              ),
        .send_data_posedge_i            (send_data_posedge_i    ),
        .clear_to_send_o                (clear_to_send_o        ),

        .data_rx_o                      (data_rx_o              ),
        .received_data_posedge_o        (),
        .received_data_parity_error_o   ()
    );


    // VIO
    wire send_data;
    reg  send_data_d;

    always @(posedge sys_clock) begin
        send_data_d <= send_data;
    end
    assign send_data_posedge_i = send_data & (~send_data_d);

    vio_0 VIRTUAL_IO (
      .clk                (sys_clock        ),

      .probe_out0         (data_tx_i        ),
      .probe_out1         (send_data        ),
      .probe_in0          (clear_to_send_o  ),
      
      .probe_in1          (data_rx_o        )
    );

endmodule
