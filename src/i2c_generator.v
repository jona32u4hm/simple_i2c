module i2c_generator (
    // Reloj y Reinicio
    input  wire        CLK,
    input  wire        RST,      // RST=1 para funcionamiento normal, 0 para reinicio

    // Interfaz con el CPU
    input  wire        RNW,
    input  wire [6:0]  I2C_ADDR,
    input  wire [15:0] WR_DATA, //write data from cpu to I2C
    output wire [15:0] RD_DATA, //read data from I2C to cpu
    input  wire        START_STB,

    // Interfaz Física I2C / Probador
    output wire        SCL,
    output wire        SDA_OUT,
    output wire        SDA_OE,
    input  wire        SDA_IN
);





i2ctx u_i2ctx (
    .clk_i(CLK),
    .rst_i(RST),
    .shift_i(), // Shift durante SCL bajo
    .write_i(), // Solo se transmite el byte menos significativo
    .srtb_i(START_STB), // Carga el shift register al iniciar la transmisión
    .sda_o(SDA_OUT)
);

i2crx u_i2crx (
    .clk_i(CLK),
    .rst_i(RST),
    .read_o(), // Solo se recibe el byte menos significativo
    .sample_i(), // Shift durante SCL alto
    .sda_i(SDA_IN)
);




wire        _scl_en;    
clk_divider u_clk_divider_i2c (
    .clk_i  (CLK),    
    .rst_i  (RST),  
    .scl_o  (SCL),    
    .scl_en (_scl_en)  
);

endmodule