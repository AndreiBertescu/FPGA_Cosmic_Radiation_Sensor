`timescale 1ns / 1ns

module top(
    input  sys_clock,
    input  btn_c,
    
    output [8-1 : 0] led
);

    wire reset;
    assign reset = btn_c;
    assign led = btn_c ? 8'ha5 : 8'h5a;


    // XADC
    wire temp_warning;
    wire temp_alarm;
    wire vcc_int_alarm;
    wire vcc_aux_alarm;

    wire[12-1 : 0] temp;
    wire[12-1 : 0] vcc_int;
    wire[12-1 : 0] vcc_aux;
    wire[12-1 : 0] vp_vn;

    xadc_wrapper xadc_wrapper_inst(
        .clk              (sys_clock      ),
        .reset_i          (reset          ),

        .vp_i             (1'b0           ),
        .vn_i             (1'b0           ),
        
        .temp_warning_o   (temp_warning   ),
        .temp_alarm_o     (temp_alarm     ),
        .vcc_int_alarm_o  (vcc_int_alarm  ),
        .vcc_aux_alarm_o  (vcc_aux_alarm  ),
        
        .temp_o           (temp           ),
        .vcc_int_o        (vcc_int        ),
        .vcc_aux_o        (vcc_aux        ),
        .vp_vn_o          (vp_vn          )       
    );
    
    
   // VIO
   vio_0 vio_inst(
       .clk         (sys_clock      ),
       
       .probe_in0   (temp           ),
       .probe_in1   (vcc_int        ),
       .probe_in2   (vcc_aux        ),
       .probe_in3   (vp_vn          ),
       
       .probe_in4   (temp_warning   ),
       .probe_in5   (temp_alarm     ),
       .probe_in6   (vcc_int_alarm  ),
       .probe_in7   (vcc_aux_alarm  )
   );

endmodule
