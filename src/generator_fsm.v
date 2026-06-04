module i2c_control_fsm (
    input       clk_i,
    input       rst_i,
    input       start_stb_i,
    input       rnw_i,
    input [1:0] clk_stage_i, // 00: low, 01: low_nxt_high, 10: high, 11: high_nxt_low

    output reg  strb_o,
    output reg  ack_o,
    output reg  shift_o,
    output reg  [7:0] write_o
);

    // Internamente: Definición de estados (IDLE, START, ADDR, ACK, etc.) y lógica de transiciones...

endmodule   