module i2crx (
    input clk_i,
    input rst_i,

    output reg [7:0] read_o,
    input sample_i,         //shift(sample) during scl high
    input sda_i
);
    reg [7:0] shift_reg;
    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            read_o <= 8'b00000000;
        end else begin
            read_o <= shift_reg; // Update output with the current shift register value
            if (sample_i) begin
                shift_reg <= {shift_reg[7:1], sda_i}; // Shift left and insert new bit from SDA
            end
        end
    end

endmodule