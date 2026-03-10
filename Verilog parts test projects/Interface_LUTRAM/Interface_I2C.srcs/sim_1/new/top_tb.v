`timescale 1ns / 1ns

module top_tb();

    reg 			clk;
    reg 			rst;
    reg [18-1 : 0] 	wr_data;
    reg [11-1 : 0]  wr_addr;
    reg        		wea;
    reg [11-1 : 0]  addr_value;
    wire [18-1 : 0] read_data_bram;
    wire [18-1 : 0] read_data_lutram;
    integer 		i;

    top DUV (
        .clk    			(clk				),
        .rst    			(rst				),
        .wr_data   			(wr_data			),
        .wr_addr  			(wr_addr			),
        .wea    			(wea				),
        .addr_value			(addr_value			),
        .read_data_bram  	(read_data_bram		),
        .read_data_lutram  	(read_data_lutram	)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz clock

    initial begin
        $display("STARTED TB");
        rst 		= 1;
        wr_data 	= 0;
        wr_addr 	= 0;
        wea		 	= 0;
        addr_value 	= 0;
        #20 rst 	= 0;


        // Write some values
//        for (i = 0; i < 2048; i = i + 1) begin
//            @(posedge clk);
//            wr_data = i * 10;
//            wr_addr = i;
//            wea = 1;
//        end

        @(posedge clk);
        wea = 0;

        // Read back values
        for (i = 0; i < 2048; i = i + 1) begin
            @(posedge clk);
            addr_value = i;
            
            if (read_data_bram !== read_data_lutram)
                $display("MISMATCH at address %0d: BRAM = %h, LUTRAM = %h", addr_value, read_data_bram, read_data_lutram);
            @(posedge clk);
        end


        repeat(20) @(posedge clk); 
        $display("ENDED TB");
        $finish;
    end

endmodule
