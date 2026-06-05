`timescale 1ns / 1ps

module tester (
    // Outputs to the DUT (CPU Side)
    output reg         CLK,
    output reg         RST,
    output reg         RNW,
    output reg [6:0]   I2C_ADDR,
    output reg [15:0]  WR_DATA,
    output reg         START_STB,
    
    // Inputs from the DUT (CPU Side)
    input      [15:0]  RD_DATA,

    // Interfacing with the I2C physical line
    input              SCL,
    input              SDA_OUT,
    input              SDA_OE,
    output reg         SDA_IN
);

    // Clock generation (50MHz)
    always #10 CLK = ~CLK;

    // Monitor I2C state changes & emulate Slave Behavior
    initial begin
        // Initialize lines
        CLK = 0;
        RST = 0;
        RNW = 0;
        I2C_ADDR = 7'h00;
        WR_DATA = 16'h0000;
        START_STB = 0;
        SDA_IN = 1; // Pull-up default

        // Release Reset
        #40;
        RST = 1;
        #20;

        // ==========================================
        // TEST CASE 1: Write Operation (Address 0x50, Data 0xA53C)
        // ==========================================
        $display("[TEST] Starting I2C Write transaction...");
        I2C_ADDR  = 7'h50; 
        WR_DATA   = 16'hA53C;
        RNW       = 1'b0; // Write
        START_STB = 1'b1;

        $display("sending ADDR");
        repeat(8) @(posedge SCL);
        START_STB = 1'b0;


        $display("Slave ADDR ACK");
        // Drive ACK during the 9th clock cycle low period
        @(negedge SCL);
        SDA_IN = 1'b0; // Send ACK
        @(negedge SCL);
        SDA_IN = 1'b1; // Release

        $display("sending high byte: ");
        // Emulate Data High Byte ACK (0xA5)
        repeat(8) @(posedge SCL);


        $display("Slave HIGH ACK");
        @(negedge SCL);
        SDA_IN = 1'b0; // Send ACK
        @(negedge SCL);
        SDA_IN = 1'b1; // Release


         $display("sending low byte: ");
        // Emulate Data Low Byte ACK (0x3C)
        repeat(8) @(posedge SCL);

        @(negedge SCL);
        SDA_IN = 1'b0; // Send ACK
        @(posedge SCL);
        SDA_IN = 1'b1; // Release

        $display("sent ");
        #200;

        // ==========================================
        // TEST CASE 2: Read Operation (Address 0x2A, Expecting Data 0x55E0)
        // ==========================================
        $display("[TEST] Starting I2C Read transaction...");
        I2C_ADDR  = 7'h2A;
        RNW       = 1'b1; // Read
        START_STB = 1'b1;


        $display("sending ADDR");
        repeat(8) @(posedge SCL);
        START_STB = 1'b0;


        $display("Slave ADDR ACK");
        // Drive ACK during the 9th clock cycle low period
        @(negedge SCL);
        SDA_IN = 1'b0; // Send ACK
        @(negedge SCL);
        SDA_IN = 1'b1; // Release
        
        $display("Sending byte");
        // Emulate providing Data Byte High (0x55 -> 01010101)
        // Bit 7
        @(negedge SCL); SDA_IN = 0; @(negedge SCL); SDA_IN = 1;
        // Bit 5
        @(negedge SCL); SDA_IN = 0; @(negedge SCL); SDA_IN = 1;
        // Bit 3
        @(negedge SCL); SDA_IN = 0; @(negedge SCL); SDA_IN = 1;
        // Bit 1
        @(negedge SCL); SDA_IN = 0; @(negedge SCL); 
        SDA_IN = 1'b1; // Release for DUT Master ACK

        $display("Waiting for Master ACK");
        // Wait for Master ACK
        @(posedge SCL); 

        // Emulate providing Data Byte Low (0xE0 -> 11100000)
        @(negedge SCL); SDA_IN = 1;
        @(negedge SCL); SDA_IN = 1;
        @(negedge SCL); SDA_IN = 1;
        @(negedge SCL); SDA_IN = 0;
        @(negedge SCL); SDA_IN = 0;
        @(negedge SCL); SDA_IN = 0;
        @(negedge SCL); SDA_IN = 0;
        @(negedge SCL); SDA_IN = 0;
        
        @(negedge SCL);
        SDA_IN = 1'b1; // Release for Master Last ACK

        repeat(8) @(posedge CLK);
        $display("[TEST] Transactions finished. Checking Read Data: %h", RD_DATA);

        $finish; 
    end

endmodule