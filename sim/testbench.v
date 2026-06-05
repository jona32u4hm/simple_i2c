//`include "build/i2c_generator_synth.v" // Archivo generado por Yosys

`include "syn/cmos_cells.v"    // Celdas de la biblioteca para simulación


`include "src/i2c_generator.v"
`include "sim/tester.v"


`timescale 1ns / 1ps

module tb_i2c_generator();

    // Interconnect wires (CPU Side)
    wire        clk;
    wire        rst;
    wire        rnw;
    wire [6:0]  i2c_addr;
    wire [15:0] wr_data;
    wire        start_stb;
    wire [15:0] rd_data;

    // Interconnect wires (I2C Physical Side)
    wire        scl;
    wire        sda_out;
    wire        sda_oe;
    wire        sda_in;
    

    // Instantiate the Tester Module
    tester u_tester (
        .CLK(clk),
        .RST(rst),
        .RNW(rnw),
        .I2C_ADDR(i2c_addr),
        .WR_DATA(wr_data),
        .START_STB(start_stb),
        .RD_DATA(rd_data),
        .SCL(scl),
        .SDA_OUT(sda_out),
        .SDA_OE(sda_oe),
        .SDA_IN(sda_in)
    );

    // Instantiate the Design Under Test (DUT)
    i2c_generator dut (
        .CLK(clk),
        .RST(rst),
        .RNW(rnw),
        .I2C_ADDR(i2c_addr),
        .WR_DATA(wr_data),
        .RD_DATA(rd_data),
        .START_STB(start_stb),
        .SCL(scl),
        .SDA_OUT(sda_out),
        .SDA_OE(sda_oe),
        .SDA_IN(sda_in) // Inout resolution handling inside the system
    );

    // Waveform setup for visualization
    initial begin
        $dumpfile("i2c_simulation.vcd");
        $dumpvars(0, tb_i2c_generator);
    end

endmodule