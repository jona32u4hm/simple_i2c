module i2c_receiver (
    input          CLK,
    input          RST,      // RST=1 normal funstion, 0 restart

    // Interfaz con el CPU
    input   [6:0]  I2C_ADDR,
    output reg [15:0] WR_DATA, // write data to cpu from I2C
    input   [15:0] RD_DATA, // read data from cpu to I2C

    // I2C 
    input           SCL,
    input           SDA_OUT,
    input           SDA_OE, //as requested by specification, it's an input, however it will not be used in logic.
    output  reg     SDA_IN
);



    reg _nxt_sda_o;
    reg [3:0] _count, _nxt_count;
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


reg scl_past, sda_past;

always @(posedge CLK or negedge RST) begin
    if (!RST) begin
        scl_past <= 1'b1;
    end else begin
        scl_past <= SCL;
        sda_past <= SDA_OUT;
    end
end
// Detects the exact CPU cycle SCL drops low
wire scl_falling_edge = (SCL == 0 && scl_past == 1);
// Detects the exact CPU cycle SCL rises high
wire scl_rising_edge  = (SCL == 1 && scl_past == 0);
wire scl_low  = (SCL == 0 && scl_past == 0);
wire scl_high = (SCL == 1 && scl_past == 1);
wire stop = (SDA_OUT == 1 && sda_past == 0 && scl_high);


    always @(*) begin
        _next_state = _state;
        _nxt_sda_o = SDA_IN;  
        _shifted = _shift;
        _nxt_rd_data = WR_DATA;
        _nxt_count = _count;
        case (_state)
            IDLE: begin
                _nxt_sda_o = 1;    
                if (SDA_OUT == 0 && scl_high) begin
                    _next_state = ADDR;
                    _nxt_count = 0;
                end
            end // ------------------------------- ADDR LOGIC -----------------------
            ADDR: begin
                if (scl_rising_edge)begin
                    _shifted = {_shift[6:0], SDA_OUT};
                    _nxt_count = _count + 1;
                end
                if (_count[3] == 1 && scl_falling_edge)begin
                    if (_shift[7:1] == I2C_ADDR) _next_state = ACK;
                    else _next_state = IDLE;
                end
            end
            ACK: begin
                _nxt_sda_o = 0; //ACK 
                if (scl_falling_edge) begin
                    // check RNW
                    if(_shift[0])begin
                        _next_state = READ_HIGH;
                        _shifted = RD_DATA[15:8];
                    end else _next_state = WRITE_HIGH;
                    _nxt_count = 3'b000;
                end
            end
            // ------------------------------------------------------------------WRITE LOGIC ---------------------------------------------------------------
            READ_HIGH: begin
                if (scl_low)begin
                    _nxt_sda_o = _shift[7];
                    _shifted = {_shift[6:0], 1'b1};
                    _nxt_count = _count + 1;
                end
                if (_count[3] && scl_falling_edge)begin
                    _next_state = READ_ACK;
                end
            end
            READ_ACK: begin
                if (scl_rising_edge && SDA_OUT == 1) begin //if NACK
                    _next_state = IDLE; 
                    _nxt_sda_o = 1;    
                end 
                if (scl_falling_edge) begin
                    _next_state = READ_LOW;
                    _nxt_count = 3'b000;
                    _shifted = RD_DATA[7:0];
                end
            end
            READ_LOW: begin
                if (scl_low)begin
                    _nxt_sda_o = _shift[7];
                    _shifted = {_shift[6:0], 1'b1};
                    _nxt_count = _count + 1;
                end
                if (_count[3]&& scl_falling_edge)begin
                    _next_state = IDLE;  // according to custom specification, only two bytes are sent and no more is required.
                end
            end
            // ------------------------------------------------------------------READ LOGIC ---------------------------------------------------------------
            WRITE_HIGH: begin
                _nxt_sda_o = 1;
                if (scl_rising_edge)begin
                    _shifted = {_shift[6:0], SDA_OUT};
                    _nxt_count = _count + 1;
                end
                if (_count[3] && scl_falling_edge)begin
                    _next_state = WRITE_ACK;
                end
            end
            WRITE_ACK: begin
                _nxt_sda_o = 0; //ACK 
                _nxt_rd_data = {_shift, 8'b0000000};
                if (scl_falling_edge) begin 
                    _next_state = WRITE_LOW;
                    _nxt_count = 3'b000;
                end
            end            
            WRITE_LOW: begin
                _nxt_sda_o = 1;
                if (scl_rising_edge)begin
                    _shifted = {_shift[6:0], SDA_OUT};
                    _nxt_count = _count + 1;
                end
                if (_count[3] && scl_falling_edge)begin
                    _next_state = LAST_ACK;
                end
            end
            LAST_ACK: begin // No ACK required according to custom specification
                _nxt_rd_data = {WR_DATA[15:8], _shift};
                _next_state = IDLE;
                _nxt_sda_o = 1;   
            end
        endcase
        if (stop) _next_state = IDLE;
    end


    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            //reset
            _state <= IDLE;
            SDA_IN <= 1'b1;
            _count <= 5'b0;
            _shift <= 8'b0;
        end else begin
            // not a reset
            _state <= _next_state;
            SDA_IN <= _nxt_sda_o;
            _count <= _nxt_count;
            _shift <= _shifted;
            WR_DATA <= _nxt_rd_data;
        end
    end





endmodule