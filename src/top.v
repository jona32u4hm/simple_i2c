module top (
    input wire        clk,
    input wire        rst_master,
    input wire        rst_slave,
    
    // CPU Interface for Generator (Master)
    input wire        rnw,
    input wire [6:0]  i2c_addr,
    input wire [15:0] wr_data,
    input wire        start_stb,
    output wire [15:0] rd_data,

    // CPU/Register Interface for Receiver (Slave)
    input wire [6:0]  slave_addr_config, // Slave's own I2C address
    output wire [15:0] wr_data_slave,
    input wire [15:0] rd_data_slave,

    // Physical I2C Bus Pins
    output wire       scl
);

    wire sda_out;
    wire sda_oe;
    wire sda_in;

    // Instantiate Master (Generator)
    i2c_generator dut_master (
        .CLK(clk),
        .RST(~rst_master),
        .RNW(rnw),
        .I2C_ADDR(i2c_addr),
        .WR_DATA(wr_data),
        .RD_DATA(rd_data),
        .START_STB(start_stb),
        .SCL(scl),
        .SDA_OUT(sda_out),
        .SDA_OE(sda_oe),
        .SDA_IN(sda_in)
    );

    // Instantiate Slave (Receiver)
    i2c_receiver dut_slave (
        .CLK(clk),
        .RST(~rst_slave),
        .I2C_ADDR(slave_addr_config),
        .WR_DATA(wr_data_slave),
        .RD_DATA(rd_data_slave),
        .SCL(scl), // Master drives SCL
        .SDA_OUT(sda_out),
        .SDA_OE(sda_oe),
        .SDA_IN(sda_in)
    );



endmodule