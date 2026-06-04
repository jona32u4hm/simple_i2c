module i2c_generator (
    // Reloj y Reinicio
    input          CLK,
    input          RST,      // RST=1 para funcionamiento normal, 0 para reinicio

    // Interfaz con el CPU
    input          RNW,
    input   [6:0]  I2C_ADDR,
    input   [15:0] WR_DATA, //write data from cpu to I2C
    output  [15:0] RD_DATA, //read data from I2C to cpu
    input          START_STB,

    // Interfaz Física I2C / Probador
    output reg        SCL,
    output reg        SDA_OUT,
    output reg        SDA_OE,
    input         SDA_IN
);


    reg _nxt_sda_o;

  
    reg [:0] _state, _next_state;
    localparam  IDLE        = 
                START       = 
                ADDR        = 

    always @(*) begin
        _next_state = _state;
        case (_state)
            IDLE: begin
                SDA_OE = 1;
                _nxt_sda_o = 1;    
                if (start_stb_i) begin
                    _next_state = SHIFT;
                    _nxt_sda_o = 0;
                end
            end
            START: begin

            end
            ADDR: begin
                
            end
        endcase
    end


    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            //reset
        end else begin
            // not a reset
            _state <= _next_state;
            SDA_OUT <= _nxt_sda_o;
        end
    end

endmodule