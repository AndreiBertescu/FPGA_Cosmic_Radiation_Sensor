/******************************************************************************
*     Project:  AICoRS
*      Author:  Stefan POPA (SP)
*       Email:  stefan.popa@unitbv.ro
*   File name:  vio_tb.v
* Description:  TTB for the BRAM SEU detector.
*
* Date			Author		Notes
* Jul   3, 2024     SP      initial version
* Jul  15, 2024     SP      adapted for the array of DEs
******************************************************************************/

`timescale 1ns / 1ns

module vio_tb (
    clk_i,
    reset_i,
    start_o,

    pop_fifo_o,
    bram_seu_addr_i,
    bram_seu_bitmap_i,
    bram_seu_index_i,
    logic_seu_i,
    scan_timer_i,
    busy_i,
    is_fifo_empty_i,

    inj_err_index_o,
    inj_err_address_o,
    inj_err_data_o,
    inj_err_valid_o
);

    parameter TP = 1;
    parameter ADDR_WIDTH = 11;
    parameter DATA_WIDTH = 18;
    parameter NR_DET_ELEM = 100;

    input clk_i;
    input reset_i;
    output reg start_o;

    output reg                          pop_fifo_o;
    input [ADDR_WIDTH - 1 : 0]          bram_seu_addr_i;
    input [DATA_WIDTH - 1 : 0]          bram_seu_bitmap_i;
    input [$clog2(NR_DET_ELEM) - 1 : 0] bram_seu_index_i;
    input                               logic_seu_i;
    input [16 - 1 : 0]                  scan_timer_i;
    input                               busy_i;
    input                               is_fifo_empty_i;

    output reg [16 - 1 : 0] inj_err_index_o;
    output reg [ADDR_WIDTH - 1 : 0] inj_err_address_o;
    output reg [DATA_WIDTH - 1 : 0] inj_err_data_o;
    output reg inj_err_valid_o;

    initial begin
        //initial values
        start_o <= 1'b0;
        inj_err_index_o <= 16'h0;
        inj_err_address_o <= 11'd0;
        inj_err_data_o <= 18'h0;
        inj_err_valid_o <= 1'b0;
        pop_fifo_o      <= 1'b0;


        //await reset deactivation
        @(negedge reset_i);
        repeat (3) @(posedge clk_i);


        //start a full DEs matrix scan
        start_o <= #TP 1'b1;
        @(posedge clk_i);
        start_o <= #TP 1'b0;

        //await the end of the scan
        @(negedge busy_i);


        //flip 4 bits 
        inj_err_valid_o <= #TP 1'b1;
        
        inj_err_index_o <= #TP 16'd6;
        inj_err_address_o <= #TP 11'd5;
        inj_err_data_o <= #TP 18'h1555d;
        @(posedge clk_i);
        
        inj_err_index_o <= #TP 16'd3;
        inj_err_address_o <= #TP 11'd9;
        inj_err_data_o <= #TP 18'h15550;
        @(posedge clk_i);
        
        inj_err_index_o <= #TP 16'd5;
        inj_err_address_o <= #TP 11'd9;
        inj_err_data_o <= #TP 18'h15553;
        @(posedge clk_i);
      
        inj_err_index_o <= #TP 16'd16;
        inj_err_address_o <= #TP 11'd7;
        inj_err_data_o <= #TP 18'h15533;
        @(posedge clk_i);

        inj_err_valid_o <= #TP 1'b0;
        inj_err_index_o <= #TP 16'd0;
        inj_err_address_o <= #TP 11'd0;
        inj_err_data_o <= #TP 18'h0;
        

        //take a break from scanning
        // 2ms = 20.000us = 2.000.000ns
        #2000

        //start a full DEs matrix scan
        @(posedge clk_i);
        start_o <= #TP 1'b1;
        @(posedge clk_i);
        start_o <= #TP 1'b0;

        //await the end of the scan
        @(negedge busy_i);

        //take a break from scanning
        // 2ms = 20.000us = 2.000.000ns
        #2000
        
        //check for detected SEUs
//        while (!is_fifo_empty_i) begin
//          pop_fifo_o <= 1'b1;
//          @(posedge clk_i);
//          pop_fifo_o <= 1'b0;
//        end
        
        //start a full DEs matrix scan
        @(posedge clk_i);
        start_o <= #TP 1'b1;
        @(posedge clk_i);
        start_o <= #TP 1'b0;

        //await the end of the scan
        @(negedge busy_i);
        
        #1000
        $display("Simulation ended!");
        $finish;
    end

endmodule
