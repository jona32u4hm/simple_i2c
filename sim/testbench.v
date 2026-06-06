`include "syn/cmos_cells.v"    // Library cells for gate-level simulation
`include "build/i2c_synth.v"    // Includes top wrapper (which includes submodules)
`include "sim/tester.v"

`timescale 1ns / 1ps

module tb_i2c_generator();

    // Interconnect wires (CPU Side / Tester Controls)
    wire        clk;
    wire        rst_master;
    wire        rst_slave;
    wire        rnw;
    wire [6:0]  i2c_addr;
    wire [15:0] wr_data;
    wire        start_stb;
    wire [15:0] rd_data;

    wire [15:0] wr_data_slave;
    wire [15:0] rd_data_slave;

    // Interconnect wires (I2C Physical Side)
    wire        scl;
    wire        sda;

    // Standard I2C Pull-up Resistor Simulation
    // If no one drives SDA (1'bz), the pull-up forces it to 1.
    assign (weak1, highz0) sda = 1'b1;

    // Instantiate the Tester Module
    tester u_tester (
        .CLK(clk),
        .MRST(rst_master),
        .SRST(rst_slave),
        .RNW(rnw),
        .I2C_ADDR(i2c_addr),
        .START_STB(start_stb),
        .MWR_DATA(wr_data),
        .MRD_DATA(rd_data),
        .SWR_DATA(wr_data_slave),
        .SRD_DATA(rd_data_slave)
    );

    // Instantiate the Unit Under Test (UUT) - The Top Wrapper
    top uut (
        .clk(clk),
        .rst_master(rst_master),
        .rst_slave(rst_slave),
        .rnw(rnw),
        .i2c_addr(i2c_addr),
        .wr_data(wr_data),
        .start_stb(start_stb),
        .rd_data(rd_data),
        
        .slave_addr_config(7'd83), // Hardcode or map a fixed address for the slave 
        .wr_data_slave(wr_data_slave),
        .rd_data_slave(rd_data_slave),
        
        .scl(scl)
    );

    // Waveform setup for visualization
    initial begin
        $dumpfile("i2c_simulation.vcd");
        $dumpvars(0, tb_i2c_generator);
    end

endmodule