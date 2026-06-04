module i2c_generator (
    // Reloj y Reinicio
    input  wire        CLK,
    input  wire        RST,      // RST=1 para funcionamiento normal, 0 para reinicio

    // Interfaz con el CPU
    input  wire [6:0]  I2C_ADDR,
    output wire [15:0] WR_DATA, // write data to cpu from I2C
    input  wire [15:0] RD_DATA, // read data from cpu to I2C

    // Interfaz Física I2C / Probador
    input   wire        SCL,
    input   wire        SDA_OUT,
    input   wire        SDA_OE,
    output  wire        SDA_IN
);








endmodule