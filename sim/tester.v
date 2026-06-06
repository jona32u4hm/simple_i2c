`timescale 1ns / 1ps

module tester (
    // Outputs to the System/DUT
    output reg        CLK,
    output reg        MRST,
    output reg        SRST,
    output reg        RNW,
    output reg [6:0]  I2C_ADDR,
    output reg        START_STB,
    output reg [15:0] MWR_DATA,
    output reg [15:0] SRD_DATA, // Data slave sends when read

    // Inputs from the System/DUT
    input      [15:0] MRD_DATA, // Data master captured from read
    input      [15:0] SWR_DATA  // Data slave captured from write
);

    // --- 1. Clock Generation ---
    // 50MHz Clock (20ns period -> toggles every 10ns)
    always begin
        #10 CLK = ~CLK;
    end

    // --- 2. Test Stimulus Logic ---
    initial begin
        // Initialize all output registers
        CLK        = 0;
        MRST       = 1;
        SRST       = 1;
        RNW        = 0;
        I2C_ADDR   = 7'h00;
        START_STB  = 0;
        MWR_DATA   = 16'h0000;
        SRD_DATA   = 16'hABCD; // Pre-load slave with data to be read

        // Hold reset for 5 clock cycles
        repeat (5) @(posedge CLK);
        #1; // Small delay to avoid racing with the clock edge
        MRST       = 0;
        SRST       = 0;
        
        repeat (2) @(posedge CLK);

        // ==========================================
        // TRANSACTION 1: Master Writes to Slave
        // ==========================================
        $display("[TESTER] Starting I2C Write Transaction...");
        I2C_ADDR   = 7'd83;          // Target Slave Address
        MWR_DATA   = 16'hCAFE;        // Data payload to write
        RNW        = 0;               // 0 = Write
        START_STB  = 1;               // Assert start strobe
        
        repeat (2) @(posedge CLK);
        #1;
        START_STB  = 0;               // De-assert strobe after 1 clock cycle

        // Wait for the transmission to finish.
        // (Adjust this delay based on your actual I2C clock speed divider)
        // For standard 100kHz I2C, a 2-byte frame takes roughly 200,000ns.
        #2500; 

        // Verify if slave captured the data correctly
        if (SWR_DATA === 16'hCAFE) begin
            $display("[TESTER] SUCCESS: Slave successfully received 16'hCAFE");
        end else begin
            $display("[TESTER] ERROR: Slave data mismatch. Expected 16'hCAFE, Got 16'h%h", SWR_DATA);
        end

        repeat (10) @(posedge CLK);

        // ==========================================
        // TRANSACTION 2: Master Reads from Slave
        // ==========================================
        $display("[TESTER] Starting I2C Read Transaction...");
        I2C_ADDR   = 7'd83;          // Target Slave Address
        RNW        = 1;               // 1 = Read
        START_STB  = 1;
        
        @(posedge CLK);
        #1;
        START_STB  = 0;

        #2500; // Wait for read sequence to completely finish

        // Verify if master captured the data sent by the slave
        if (MRD_DATA === 16'hABCD) begin
            $display("[TESTER] SUCCESS: Master successfully read 16'hABCD");
        end else begin
            $display("[TESTER] ERROR: Master data mismatch. Expected 16'hABCD, Got 16'h%h", MRD_DATA);
        end

        // ============================================================================================================================
        // ADDITIONAL TESTS
        // ============================================================================================================================



        // ==========================================
        // ADDITIONAL TEST 1: Back-to-Back Transactions
        // ==========================================
        $display("[TESTER] Starting Back-to-Back Test...");
        I2C_ADDR   = 7'd83;          // Target Slave Address      
        MWR_DATA   = 16'h1111;        
        RNW        = 0;               
        START_STB  = 1;               
        @(posedge CLK); #1; START_STB = 0;
        
        #2250; // Wait for transaction to end

        // Immediate next transaction (No idle rest)
        I2C_ADDR   = 7'd83;          // Target Slave Address     
        MWR_DATA   = 16'h2222;        
        RNW        = 0;               
        START_STB  = 1;               
        @(posedge CLK); #1; START_STB = 0;
        
        #2250; 

        // Immediate next transaction (No idle rest and different address)
        I2C_ADDR   = 7'd11;          
        MWR_DATA   = 16'h2222;        
        RNW        = 0;               
        START_STB  = 1;               
        @(posedge CLK); #1; START_STB = 0;
        
        #2500; 
        
        // ==========================================
        // ADDITIONAL TEST 2: Mid-Transaction Reset
        // ==========================================
        $display("[TESTER] Starting Mid-Transaction Reset Test...");
        I2C_ADDR   = 7'd83;          // Target Slave Address
        MWR_DATA   = 16'h9999;
        RNW        = 0;
        START_STB  = 1;
        @(posedge CLK); #1; START_STB = 0;

        #500; // Wait until it's halfway through transmitting
        $display("[TESTER] CRITICAL: Asserting Reset Mid-Stream!");
        MRST = 1; 
        SRST = 1;
        repeat (3) @(posedge CLK);
        #1;
        MRST = 0;
        SRST = 0;
        
        // Verify state machine returned to 0 safely
        // (Add your DUT state check here if accessible)




        // End Simulation
        repeat (20) @(posedge CLK);
        $display("[TESTER] Simulation finished cleanly.");
        $finish;
    end

endmodule