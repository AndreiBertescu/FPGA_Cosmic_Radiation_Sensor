`timescale 1ns / 1ns

module xadc_wrapper(
    input clk,
    input reset_i,

    input vp_i,
    input vn_i,
    
    output temp_warning_o,
    output temp_alarm_o,
    output vcc_int_alarm_o,
    output vcc_aux_alarm_o,
    
    output reg[12-1 : 0] temp_o,      // Temp[C] = (temp * 0.123) - 273.15
    output reg[12-1 : 0] vcc_int_o,   // voltage[V] = (vcc_int / 4096) * 3
    output reg[12-1 : 0] vcc_aux_o,   // voltage[V] = (vcc_aux / 4096) * 3
    output reg[12-1 : 0] vp_vn_o      // Check UG480
);

    reg             den_in;
    reg [7-1 : 0]   daddr_in;
    wire [5-1 : 0]  channel_out;
    wire [16-1 : 0] do_out;
    wire            drdy_out;
    
    
    // tie outputs to inputs
    always @(posedge clk or posedge reset_i) begin
        if(reset_i) begin
            den_in   <= 1'b0;
            daddr_in <= {7{1'b0}};
        end else begin
            den_in   <= eoc_out;
            daddr_in <= {2'b00, channel_out};
        end
    end
    
    
    // XADC
    xadc_wiz_0 xadc_wiz_inst (
        .dclk_in            (clk            ),
        .reset_in           (reset_i        ),
        .vp_in              (vp_i           ),
        .vn_in              (vn_i           ),

        .busy_out           (busy_out       ),
        .den_in             (den_in         ),
        .daddr_in           (daddr_in       ),
        .drdy_out           (drdy_out       ),
        .eoc_out            (eoc_out        ),

        .channel_out        (channel_out    ),
        .do_out             (do_out         ),
        .di_in              (16'h000        ),
        .dwe_in             (1'b0           ),
        .eos_out            (               ),
        
        .ot_out             (temp_alarm_o   ),
        .vccaux_alarm_out   (vcc_aux_alarm_o),
        .vccint_alarm_out   (vcc_int_alarm_o),
        .user_temp_alarm_out(temp_warning_o ),
        .alarm_out          (               )   
    );


    // Outputs
    always @(posedge clk or posedge reset_i) begin
        if(reset_i) begin
            temp_o    <= {16{1'b0}};
            vcc_int_o <= {16{1'b0}};
            vcc_aux_o <= {16{1'b0}};
            vp_vn_o   <= {16{1'b0}};
        end else if(drdy_out) begin
            case (daddr_in)
                7'h0 : temp_o     <= do_out[15 : 4];
                7'h1 : vcc_int_o  <= do_out[15 : 4];
                7'h2 : vcc_aux_o  <= do_out[15 : 4];
                default : vp_vn_o <= do_out[15 : 4];
            endcase
        end
    end

endmodule
