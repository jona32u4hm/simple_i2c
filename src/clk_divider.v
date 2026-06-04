module clk_divider (
    input  wire  clk_i,
    input  wire  rst_i,          // Active high reset (RST=1 normal, 0 reinicio)
    
    output reg   scl_o,          //  I2C clock scl at 25% clk frequency
    input        scl_en
);

    
    reg [1:0] _state;
    localparam  LOW        = 2'b00,
                LOW_WAIT   = 2'b01,
                HIGH       = 2'b11,
                HIGH_WAIT  = 2'b10;

    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            _state           <= HIGH_WAIT;
            scl_o          <= 1'b1;
            sample_pulse_o <= 1'b0;
            drive_pulse_o  <= 1'b0;
        end 
        else if (scl_en) _state <= _next_state; 
        else _state <= HIGH_WAIT; 
    end
    always @(negedge clk_i) begin
        case(_state)
            LOW: begin
                scl_o          <= 1'b1; 
                _state          <= LOW_WAIT;
            end
            LOW_WAIT: begin
                scl_o          <= 1'b1; 
                sample_pulse_o <= 1'b0;
                drive_pulse_o  <= 1'b0;
                _state           <= HIGH;
            end
            HIGH: begin
                scl_o          <= 1'b0; 
                sample_pulse_o <= 1'b0;
                drive_pulse_o  <= 1'b1; 
                _state           <= HIGH_WAIT;
            end
            HIGH_WAIT: begin
                scl_o          <= 1'b0; 
                sample_pulse_o <= 1'b0;
                drive_pulse_o  <= 1'b0;
                _state           <= LOW;
            end
    end

endmodule