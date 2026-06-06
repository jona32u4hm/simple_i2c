
//`include "build/i2c_receiver_synth.v" // Archivo generado por Yosys

`include "syn/cmos_cells.v"    // Celdas de la biblioteca para simulación


`include "src/i2c_receiver.v"
`include "sim/slave_tester.v"
`timescale 1ns / 1ps

module i2c_receiver_tb;

    // Clock is generated here, so it remains a reg
    reg         CLK;
    
    // Fixed: Signals driven by the tester outputs MUST be wires at the top level
    wire         RST;
    wire  [6:0]  I2C_ADDR;
    wire  [15:0] RD_DATA;
    wire         SCL;
    wire         SDA_OUT;
    wire         SDA_OE;

    // Outputs coming directly from the DUT
    wire [15:0] WR_DATA;
    wire        SDA_IN;

    // 1. Clock Generation (50MHz System Clock)
    initial CLK = 0;
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
        .CLK(CLK), // Input to tester
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
        $dumpfile("i2c_simulation.vcd");
        $dumpvars(0, i2c_receiver_tb);
    end

endmodule