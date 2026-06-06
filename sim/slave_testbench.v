`timescale 1ns / 1ps

module i2c_receiver_tb;

    // Inputs to DUT
    reg         CLK;
    reg         RST;
    reg  [6:0]  I2C_ADDR;
    reg  [15:0] RD_DATA;
    reg         SCL;
    reg         SDA_OUT;
    reg         SDA_OE;

    // Outputs from DUT
    wire [15:0] WR_DATA;
    wire        SDA_IN;

    // 1. Clock Generation (50MHz System Clock)
    always begin
        #10 CLK = ~CLK; 
    end

    // 2. Instantiate the Design Under Test (DUT)
    i2c_receiver dut (
        .CLK(CLK),
        .RST(RST),
        .I2C_ADDR(I2C_ADDR),
        .WR_DATA(WR_DATA),
        .RD_DATA(RD_DATA),
        .SCL(SCL),
        .SDA_OUT(SDA_OUT),
        .SDA_OE(SDA_OE),
        .SDA_IN(SDA_IN)
    );

    // 3. Instantiate the Tester Module to drive stimulus
    tester test_driver (
        .CLK(CLK),
        .RST(RST),
        .I2C_ADDR(I2C_ADDR),
        .RD_DATA(RD_DATA),
        .SCL(SCL),
        .SDA_OUT(SDA_OUT),
        .SDA_OE(SDA_OE),
        .SDA_IN(SDA_IN),
        .WR_DATA(WR_DATA)
    );

    // 4. Waveform generation setup
    initial begin
        $dumpfile("i2c_receiver_dump.vcd");
        $dumpvars(0, i2c_receiver_tb);
    end

endmodule