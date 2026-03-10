`timescale 1ns / 1ns

module spi_block_V3_tb();

    localparam HALF_100_MHZ_CLOCK_PERIOD    = 5; //half of the period of the 100 MHz clock
    localparam TP                           = 2;
    localparam FRAME_WIDTH                  = 32;

    reg                   		clk;
    reg                   		spi_clk;
    reg                   		reset_i;
	
	reg [FRAME_WIDTH-1 : 0] 	data_i;
	wire 						busy_o;

    reg      					spi_cs_i;
    reg      					spi_clk_i;
    wire       					spi_data_o;
    reg       					spi_data_i;    


    // Clock generator
    initial begin
        clk <= 1'b0;
        forever begin
            #(HALF_100_MHZ_CLOCK_PERIOD*10) clk <= ~clk;
        end
    end
	
	// SPI clock generator
    initial begin
        spi_clk <= #TP 1'b0;
        forever begin
            #(HALF_100_MHZ_CLOCK_PERIOD) spi_clk <= #TP ~spi_clk;
        end
    end
    

    // Main test loop
    initial begin
        data_i    		= 0;
        spi_cs_i	    = 1;
        spi_data_i   	= 0;
		spi_clk_i       = 0;

        // Wait reset
        reset_i = 0;
        @(posedge clk);
        reset_i = 1;
        repeat (10) @(posedge clk);
        reset_i = 0;

        // Start transaction
        data_i = #TP 'h91111119;
        @(posedge spi_clk);
        spi_cs_i = #TP 0;

        repeat (FRAME_WIDTH) @(posedge spi_clk);
        spi_cs_i = #TP 1;
        
        repeat (30) @(posedge clk);
        $finish;
    end


    // DUV
    spi_block_V3_fast #(
        .TP                 (TP                 ),
        .FRAME_WIDTH      	(FRAME_WIDTH        ),
        .SPI_MODE 	     	(0          		),
        .IS_LSB_FIRST     	(0					)
    ) DUV (
        .clk_i              (clk                ),
        .reset_i            (reset_i            ),
		
		.data_i				(data_i				),
		.busy_o				(busy_o				),

		.spi_cs_i			(spi_cs_i			),
		.spi_clk_i			(spi_clk  			),
		.spi_data_o			(spi_data_o			),
		.spi_data_i			(spi_data_i			)
    );

endmodule