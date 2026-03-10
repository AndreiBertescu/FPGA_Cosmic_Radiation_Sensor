`timescale 1ns / 1ns

module uart_block #(
    parameter TP             = 1,
    parameter PARITY_BIT     = "even",  // odd / even
    parameter FREQ           = 100_000_000,  // 100 MHz
    parameter BAUD           = 9600,
    parameter LSB_FIRST      = 1,
    parameter RX_FILTER_SIZE = 16
)( 
    input                clk,
    input                reset_i,
    input                rx,
    output               tx,

    input[8-1 : 0]       data_tx_i,
    input                send_data_posedge_i,
    output               clear_to_send_o,

    output reg [8-1 : 0] data_rx_o,
    output reg           received_data_posedge_o,
    output               received_data_parity_error_o
);

    // tx signals
    reg [10-1 : 0]              shift_reg_tx;
    reg [4-1 : 0]               counter_tx;
    reg                         sending_data;
    wire                        parity_tx;
    assign                      parity_tx = (PARITY_BIT == "even") ? ^data_tx_i : ~(^data_tx_i);
    reg                         send_data_posedge_baud;
    
    // rx signals
    reg [RX_FILTER_SIZE - 1:0]  rx_samples;
    reg [10-1 : 0]              shift_reg_rx;
    reg [4-1 : 0]               counter_rx;
    reg                         receiving_data;
    wire                        parity_rx;
    assign                      parity_rx = (PARITY_BIT == "even") ? ^data_rx_o : ~(^data_rx_o);
    
    
    // Baud clock
    clock_divider #(
        .FREQ_IN    (FREQ       ),
        .FREQ_OUT   (BAUD       ),
        .MAKE_PULSE (1          )
    ) clock_divider_baud (
        .clk        (clk        ),
        .reset_i    (reset_i    ),
        .clk_o      (baud_clk   )
    );
    
    
////// TX

    // Paralel to serial register
    always @(posedge clk or posedge reset_i) begin
        if(reset_i)
            shift_reg_tx <= #TP {10{1'b1}};
        else if(send_data_posedge_baud & baud_clk)
            shift_reg_tx <= #TP (LSB_FIRST) ? {1'b0, data_tx_i, parity_tx} : {parity_tx, data_tx_i, 1'b0};
        else if(baud_clk)
            shift_reg_tx <= #TP (LSB_FIRST) ? {shift_reg_tx[8 : 0], 1'b1} : {1'b1, shift_reg_tx[9 : 1]};  
    end
    
    assign tx = (LSB_FIRST) ? shift_reg_tx[9] : shift_reg_tx[0];
    
    
    // send_data_posedge_baud - makes send_data_posedge_i last until baud_clk signal
    always @(posedge clk or posedge reset_i) begin
        if(reset_i)
            send_data_posedge_baud <= #TP 1'b0;
        else if(send_data_posedge_baud & baud_clk)
            send_data_posedge_baud <= #TP 1'b0;
        else if(send_data_posedge_i)
            send_data_posedge_baud <= #TP 1'b1;
    end
    
    
    // Flow control - sets sending_data
    always @(posedge clk or posedge reset_i) begin
        if(reset_i)
            sending_data <= #TP 1'b0;
        else if(counter_tx == 4'd11 & baud_clk)
            sending_data <= #TP 1'b0;
        else if(send_data_posedge_baud)
            sending_data <= #TP 1'b1;
    end
    assign clear_to_send_o = ~sending_data;
    
    always @(posedge clk or posedge reset_i) begin
        if(reset_i)
            counter_tx <= #TP {4{1'b0}};
        else if(counter_tx == 4'd11 & baud_clk)
            counter_tx <= #TP {4{1'b0}};
        else if(sending_data & baud_clk)
            counter_tx <= #TP counter_tx + 1;
    end
    
    
////// RX

    // Serial to paralel register
    always @(posedge clk or posedge reset_i) begin
        if(reset_i)
            shift_reg_rx <= #TP {10{1'b0}};
        else if(baud_clk)
            shift_reg_rx <= #TP (LSB_FIRST) ? {shift_reg_rx[8 : 0], rx} : {rx, shift_reg_rx[9 : 1]};  
    end
    
    
    // Assigns output when finished
    always @(posedge clk or posedge reset_i) begin
        if(reset_i)
            data_rx_o <= #TP {8{1'b0}};
        else if(counter_rx == 4'd9 & baud_clk)
            data_rx_o <= #TP shift_reg_rx[8 : 1];  
    end
    
    assign received_data_parity_error_o = (LSB_FIRST) ? (shift_reg_rx[0] ^ parity_rx) : (shift_reg_rx[8] ^ parity_rx);
    
    
    // RX filter - samples rx multiple times to make sure a start bit is actually received 
    always @(posedge clk) begin
        rx_samples <= {rx_samples[RX_FILTER_SIZE - 2 : 0], rx};
    end
    
    // Flow control - sets receiving_data and received_data_posedge_o
    always @(posedge clk or posedge reset_i) begin
        if(reset_i)
            receiving_data <= #TP 1'b0;
        else if(counter_rx == 4'd10 & baud_clk)
            receiving_data <= #TP 1'b0;
        else if(rx_samples == {RX_FILTER_SIZE{1'b0}} & baud_clk)
            receiving_data <= #TP 1'b1;
    end
    
    always @(posedge clk or posedge reset_i) begin
        if(reset_i)
            counter_rx <= #TP {4{1'b0}};
        else if(counter_rx == 4'd10 & baud_clk)
            counter_rx <= #TP {4{1'b0}};
        else if(receiving_data & baud_clk)
            counter_rx <= #TP counter_rx + 1;
    end
    
    always @(posedge clk or posedge reset_i) begin
        if(reset_i)
            received_data_posedge_o <= #TP 1'b0;
        else if(received_data_posedge_o)
            received_data_posedge_o <= #TP 1'b0;
        else if(counter_rx == 4'd9 & baud_clk)
            received_data_posedge_o <= #TP 1'b1;
    end

endmodule
