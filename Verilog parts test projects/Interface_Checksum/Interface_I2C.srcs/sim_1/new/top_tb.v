`timescale 1ns / 1ns

module top_tb();
    
    localparam WIDTH_IN   = 12;
    localparam WIDTH_OUT  = 4;
    
    reg  [WIDTH_IN-1 : 0]   signal;
    wire [16-1 : 0]         signal_2;
    wire [WIDTH_OUT-1 : 0]  checksum;
    wire [WIDTH_OUT-1 : 0]  checksum_2;

    top #(
        .WIDTH_IN    (WIDTH_IN  ),
        .WIDTH_OUT   (WIDTH_OUT )
    ) DUV (
        .signal_i    (signal    ),
        .signal_o    (signal_2  ),
        .checksum_o  (checksum  )
    );
    
    top #(
        .WIDTH_IN    (16        ),
        .WIDTH_OUT   (WIDTH_OUT )
    ) DUV_2 (
        .signal_i    (signal_2  ),
        .checksum_o  (checksum_2)
    );


    initial begin
        $display("STARTED TB");
        
        #20;
        signal = 'b101011101011;
        
        #20;
        signal = 'b000011111111;
        
        #20;
        signal = 'b111111111111;

        #40;
        $display("ENDED TB");
        $finish;
    end

endmodule
