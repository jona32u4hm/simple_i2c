module i2c_generator (
    // Reloj y Reinicio
    input          CLK,
    input          RST,      // RST=1 para funcionamiento normal, 0 para reinicio

    // Interfaz con el CPU
    input          RNW,
    input   [6:0]  I2C_ADDR,
    input   [15:0] WR_DATA, //write data from cpu to I2C
    output reg [15:0] RD_DATA, //read data from I2C to cpu
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
    reg [15:0]_nxt_rd_data;
  
    reg [11:0] _state, _next_state;
    localparam  IDLE        = 12'b1,
                START       = 12'b10,
                ADDR        = 12'b100,
                ACK         = 12'b1000,
                WRITE_HIGH  = 12'b10000,
                WRITE_ACK   = 12'b100000,
                WRITE_LOW   = 12'b1000000,
                WAIT_ACK    = 12'b10000000,
                READ_HIGH   = 12'b100000000,
                READ_ACK    = 12'b1000000000,
                READ_LOW    = 12'b10000000000,
                LAST_ACK    = 12'b100000000000;

    always @(*) begin
        SDA_OE = 1;
        _next_state = _state;
        _nxt_sda_o = SDA_OUT;  
        _shifted = _shift;
        _nxt_rd_data = RD_DATA;
        case (_state)
            IDLE: begin
                _nxt_stage_count = 5'b11111;
                _nxt_sda_o = 1;    
                if (START_STB) begin
                    _next_state = START;
                    _nxt_sda_o = 0;
                end
            end
            START: begin
                _nxt_stage_count = _stage_count +1;
                _nxt_sda_o = 0;  
                _next_state = ADDR;
                _shifted = {I2C_ADDR, RNW};
            end
            ADDR: begin
                _nxt_stage_count = _stage_count +1;
                if (_stage_count[1:0] == 2'b00)begin
                    _nxt_sda_o = _shift[7];
                    _shifted = {_shift[6:0], 1'b1};
                end
                if (_stage_count[4:0] == 5'b11111)begin
                    _next_state = ACK;
                end
            end
            ACK: begin
                _nxt_stage_count = _stage_count +1;
                if (_stage_count != 0) begin
                    SDA_OE = 0;
                    if (_stage_count[1:0] == 2'b10 && SDA_IN == 1) begin //if NACK
                        _next_state = IDLE; 
                        _nxt_sda_o = 1;    
                    end 
                    if (_stage_count[1:0] == 2'b11) begin
                        _next_state = (RNW)? READ_HIGH : WRITE_HIGH;
                        _nxt_stage_count = 5'b00000;
                        _shifted = WR_DATA[15:8];
                    end
                end
            end
            // ------------------------------------------------------------------WRITE LOGIC ---------------------------------------------------------------
            WRITE_HIGH: begin
                _nxt_stage_count = _stage_count +1;
                if (_stage_count[1:0] == 2'b00)begin
                    _nxt_sda_o = _shift[7];
                    _shifted = {_shift[6:0], 1'b1};
                end
                if (_stage_count[4:0] == 5'b11111)begin
                    _next_state = WRITE_ACK;
                end
            end
            WRITE_ACK: begin
                _nxt_stage_count = _stage_count +1;
                if (_stage_count != 0) begin
                    SDA_OE = 0;
                    if (_stage_count[1:0] == 2'b10 && SDA_IN == 1) begin //if NACK
                        _next_state = IDLE; 
                        _nxt_sda_o = 1;    
                    end 
                    if (_stage_count[1:0] == 2'b11) begin
                        _next_state = WRITE_LOW;
                        _nxt_stage_count = 5'b00000;
                        _shifted = WR_DATA[7:0];
                    end
                end
            end
            WRITE_LOW: begin
                _nxt_stage_count = _stage_count +1;
                if (_stage_count[1:0] == 2'b00)begin
                    _nxt_sda_o = _shift[7];
                    _shifted = {_shift[6:0], 1'b1};
                end
                if (_stage_count[4:0] == 5'b11111)begin
                    _next_state = WAIT_ACK;
                end
            end
            WAIT_ACK: begin
                _nxt_stage_count = _stage_count +1;
                if (_stage_count != 0) begin
                    SDA_OE = 0;
                    if (_stage_count[1:0] == 2'b11) begin 
                        _nxt_stage_count = 5'b11111;
                        _nxt_sda_o = 1;    
                        _next_state = IDLE;  //STOP
                    end 
                end
            end
            // ------------------------------------------------------------------READ LOGIC ---------------------------------------------------------------
            READ_HIGH: begin
                _nxt_stage_count = _stage_count +1;
                SDA_OE = 0;
                if (_stage_count[1:0] == 2'b10)begin
                    _shifted = {_shift[6:0], SDA_IN};
                end
                if (_stage_count[4:0] == 5'b11111)begin
                    _next_state = READ_ACK;
                end
            end
            READ_ACK: begin
                _nxt_sda_o = 0; //ACK 
                _nxt_rd_data = {_shift, 8'b0000000};
                _nxt_stage_count = _stage_count +1;
                if (_stage_count == 0) SDA_OE = 0;
                else begin
                    if (_stage_count[2:0] == 3'b100) begin // Extended one more cycle to keep SDA_OE enabled
                        _next_state = READ_LOW;
                        _nxt_stage_count = 5'b00001;
                    end
                end
            end            
            READ_LOW: begin
                SDA_OE = 0;
                _nxt_stage_count = _stage_count +1;
                SDA_OE = 0;
                if (_stage_count[1:0] == 2'b10)begin
                    _shifted = {_shift[6:0], SDA_IN};
                end
                if (_stage_count[4:0] == 5'b11111)begin
                    _next_state = LAST_ACK;
                end
            end
            LAST_ACK: begin
                _nxt_sda_o = 0; //ACK
                _nxt_rd_data = {RD_DATA[15:8], _shift};
                _nxt_stage_count = _stage_count +1;
                if (_stage_count == 0) SDA_OE = 0;
                else begin
                    if (_stage_count[2:0] == 3'b110) begin
                        _next_state = IDLE;
                        _nxt_stage_count = 5'b11111;
                        _nxt_sda_o = 1;    
                    end
                end
            end
        endcase
    end


    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            //reset
            _state <= IDLE;
            SDA_OUT <= 1'b1;
            SCL <= 1'b1;
            SDA_OE <= 1'b0;
            _stage_count <= 5'b0;
            _shift <= 8'b0;
        end else begin
            // not a reset
            _state <= _next_state;
            SDA_OUT <= _nxt_sda_o;
            SCL <= _nxt_stage_count[1];
            _stage_count <= _nxt_stage_count;
            _shift <= _shifted;
            RD_DATA <= _nxt_rd_data;
        end
    end

endmodule