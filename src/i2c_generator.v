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
    reg [4:0] _stage_count, _nxt_stage_count;
    reg [7:0] _shift, _shifted;

  
    reg [:0] _state, _next_state;
    localparam  IDLE        = 
                START       = 
                ADDR        = 
                ACK         =

    always @(*) begin
        SDA_OE = 1;
        _next_state = _state;
        _scl = 1;
        _nxt_sda_o = SDA_OUT;  
        _shifted = _shift;
        case (_state)
            IDLE: begin
                _nxt_stage_count = 2'b11;
                _nxt_sda_o = 1;    
                if (start_stb_i) begin
                    _next_state = START;
                    _nxt_sda_o = 0;
                end
            end
            START: begin
                _nxt_stage_count = _stage_count +1;
                _nxt_sda_o = 0;  
                _next_state = ADDR;
                _shifted = I2C_ADDR;
            end
            ADDR: begin
                _nxt_stage_count = _stage_count +1;
                if (_stage_count[1:0] == 2'b00)begin
                    _nxt_sda_o = _shift[7];
                    _shifted = {shift_reg[6:0], 1'b1};
                end
                if (_stage_count[4:2] == 3'b111)begin
                    _next_state = ACK;
                end
            end
            ACK: begin
                _nxt_stage_count = _stage_count +1;
                if (_stage_count != 0) begin
                    SDA_OE = 0;
                    if (_stage_count[1:0] == 2'b10 && SDA_IN == 0) begin //if NACK
                        _next_state = IDLE; 
                    end 
                    if (_stage_count[2] == 1'b1) begin
                        _next_state = DATA
                    end
                end
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
            SCL <= _nxt_stage_count[1];
            _stage_count <= _nxt_stage_count;
            _shift <= _shifted;
        end
    end

endmodule