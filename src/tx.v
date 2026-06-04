module i2ctx (
    input clk_i,
    input rst_i,

    input shift_i,      // shift during scl low

    input [7:0] write_i,
    input srtb_i,
    output reg sda_o
);
    reg [7:0] shift_reg;
    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            sda_o <= 1'b1;
        end else begin
            if (srtb_i) begin
                shift_reg <= write_i;
            end else if (shift_i) begin
                    sda_o <= shift_reg[7];
                    shift_reg <= {shift_reg[6:0], 1'b1}; // Shift left
            end
        end
    end

endmodule  