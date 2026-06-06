`timescale 1ns / 1ps

module tester (
    input  wire        CLK,
    output reg         RST,
    output reg  [6:0]  I2C_ADDR,
    output reg  [15:0] RD_DATA,
    output reg         SCL,
    output reg         SDA_OUT,
    output reg         SDA_OE,
    input  wire        SDA_IN,
    input  wire [15:0] WR_DATA
);

    // Helper task to handle an I2C Bit stream transmission
    task send_i2c_bit(input bit_val);
        begin
            SDA_OUT = bit_val;
            #40 SCL = 1; // Pull SCL High
            #40 SCL = 0; // Pull SCL Low
        end
    endtask

    initial begin
        // --- Step 1: Initialization & Reset ---
        RST      = 0;  // Trigger active-low reset
        I2C_ADDR = 7'h5A; // Configure the Receiver module's target address
        RD_DATA  = 16'hABCD;
        SCL      = 1;
        SDA_OUT  = 1;
        SDA_OE   = 1;
        
        #40;
        RST      = 1;  // Release reset, normal operation active
        #20;

        $display("At time %0t: --- Starting I2C Receiver Test Environment ---", $time);
        $monitor("At time %0t: SDA_IN (ACK from Receiver) = %b | WR_DATA = %h", $time, SDA_IN, WR_DATA);

        // --- Step 2: Send I2C START Condition ---
        #20;
        SDA_OUT = 0; 
        #20;
        SCL = 0;     
        #20;

        // --- Step 3: Send Matching 7-bit Address (7'h5A -> binary 1011010) ---
        send_i2c_bit(1); // Bit 6
        send_i2c_bit(0); // Bit 5
        send_i2c_bit(1); // Bit 4
        send_i2c_bit(1); // Bit 3
        send_i2c_bit(0); // Bit 2
        send_i2c_bit(1); // Bit 1
        send_i2c_bit(0); // Bit 0

        // --- Step 4: Send the Write Bit (0 = Write) ---
        send_i2c_bit(0); 

        // --- Step 5: Wait for ACK Phase ---
        SDA_OUT = 1; 
        #40 SCL = 1;
        #20;
        
        if (SDA_IN == 0) begin
            $display("At time %0t: SUCCESS - Device generated an ACK for matching Address!", $time);
        end else begin
            $display("At time %0t: WARNING - Device did not ACK address match.", $time);
        end
        
        #20 SCL = 0;

        // ====================================================================
        // --- Step 6: Send Data Byte to Receiver (e.g., 8'hA5 -> 10100101) ---
        // ====================================================================
        $display("At time %0t: --- Sending Data Byte: 8'hA5 ---", $time);
        
        // We will transmit the byte 8'hA5 (MSB first: 1, 0, 1, 0, 0, 1, 0, 1)
        send_i2c_bit(1); // Bit 7
        send_i2c_bit(0); // Bit 6
        send_i2c_bit(1); // Bit 5
        send_i2c_bit(0); // Bit 4
        send_i2c_bit(0); // Bit 3
        send_i2c_bit(1); // Bit 2
        send_i2c_bit(0); // Bit 1
        send_i2c_bit(1); // Bit 0

        // --- Step 7: Wait for Data ACK Phase ---
        SDA_OUT = 1;      // Release the SDA line so the receiver can drive it
        #40 SCL = 1;      // Pull SCL High to sample the ACK
        #20;
        
        if (SDA_IN == 0) begin
            $display("At time %0t: SUCCESS - Device generated an ACK for the Data Byte!", $time);
        end else begin
            $display("At time %0t: WARNING - Device did not ACK the Data Byte.", $time);
        end
        
        #20 SCL = 0;      // Pull SCL Low to finalize the bit cycle
        #40;

        // --- Step 8: Send I2C STOP Condition ---
        SDA_OUT = 0;      // Ensure SDA is low while SCL is low
        #20;
        SCL = 1;          // Pull SCL High
        #20;
        SDA_OUT = 1;      // Transition SDA Low -> High while SCL is High (STOP)
        #40;



        #100;

        // Finish up simulation
        $display("At time %0t: --- Test Script Execution Complete ---", $time);
        $finish;
    end

endmodule