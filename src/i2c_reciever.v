module i2c_reciever (
    input  wire        CLK,
    input  wire        RST,      // RST=1 normal funstion, 0 restart

    // Interfaz con el CPU
    input  wire [6:0]  I2C_ADDR,
    output wire [15:0] WR_DATA, // write data to cpu from I2C
    input  wire [15:0] RD_DATA, // read data from cpu to I2C

    // I2C 
    input   wire        SCL,
    input   wire        SDA_OUT,
    input   wire        SDA_OE, //as requested by specification, it's an input, however it will not be used in logic.
    output  wire        SDA_IN
);



    reg _nxt_sda_o;
    reg [4:0] _stage_count, _nxt_stage_count;
    reg [7:0] _shift, _shifted;
    reg [15:0]_nxt_rd_data;
  
    reg [11:0] _state, _next_state;
    localparam  IDLE        = 12'b1,
                ADDR        = 12'b10,
                ACK         = 12'b100,
                WRITE_HIGH  = 12'b1000,
                WRITE_ACK   = 12'b10000,
                WRITE_LOW   = 12'b100000,
                READ_HIGH   = 12'b1000000,
                READ_ACK    = 12'b10000000,
                READ_LOW    = 12'b100000000,
                LAST_ACK    = 12'b1000000000;

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
                if (SDA_OUT == 0) begin
                    _next_state = ADDR;
                end
            end // ------------------------------- ADDR LOGIC -----------------------
            ADDR: begin
                _nxt_stage_count = _stage_count +1;
                if (_stage_count[1:0] == 2'b10)begin
                    _shifted = {_shift[6:0], SDA_IN};
                end
                if (_stage_count[4:0] == 5'b11111)begin
                    if (_shift[7:1] == I2C_ADDR) _next_state = ACK;
                    else _next_state = IDLE;
                end
            end
            ACK: begin
                _nxt_sda_o = 0; //ACK 
                _nxt_stage_count = _stage_count +1;
                else begin
                    if (_stage_count[1:0] == 3'b11) begin
                        // check RNW
                        if(_shift[1])begin
                            _next_state = READ_HIGH;
                            _shifted = RD_DATA[15:8];
                        end else _next_state = WRITE_HIGH;
                        _nxt_stage_count = 5'b00000;
                    end
                end
            end
            // ------------------------------------------------------------------WRITE LOGIC ---------------------------------------------------------------
            READ_HIGH: begin
                _nxt_stage_count = _stage_count +1;
                if (_stage_count[1:0] == 2'b00)begin
                    _nxt_sda_o = _shift[7];
                    _shifted = {_shift[6:0], 1'b1};
                end
                if (_stage_count[4:0] == 5'b11111)begin
                    _next_state = READ_ACK;
                end
            end
            READ_ACK: begin
                _nxt_stage_count = _stage_count +1;
                if (_stage_count[1:0] == 2'b10 && SDA_IN == 1) begin //if NACK
                    _next_state = IDLE; 
                    _nxt_sda_o = 1;    
                end 
                if (_stage_count[1:0] == 2'b11) begin
                    _next_state = READ_LOW;
                    _nxt_stage_count = 5'b00000;
                    _shifted = RD_DATA[7:0];
                end
            end
            READ_LOW: begin
                _nxt_stage_count = _stage_count +1;
                if (_stage_count[1:0] == 2'b00)begin
                    _nxt_sda_o = _shift[7];
                    _shifted = {_shift[6:0], 1'b1};
                end
                if (_stage_count[4:0] == 5'b11111)begin
                    _next_state = WAIT_ACK;
                    _nxt_stage_count = 5'b11111;
                    _next_state = IDLE;  // according to specification, only two bytes are sent and no more is required.
                end
            end
            // ------------------------------------------------------------------READ LOGIC ---------------------------------------------------------------
            WRITE_HIGH: begin
                _nxt_stage_count = _stage_count +1;
                SDA_OE = 0;
                if (_stage_count[1:0] == 2'b10)begin
                    _shifted = {_shift[6:0], SDA_IN};
                end
                if (_stage_count[4:0] == 5'b11111)begin
                    _next_state = READ_ACK;
                end
            end
            WRITE_ACK: begin
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
            WRITE_LOW: begin
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
            SDA_IN <= _nxt_sda_o;
            _stage_count <= _nxt_stage_count;
            _shift <= _shifted;
            WR_DATA <= _nxt_rd_data;
        end
    end





endmodule