//=============================================================================
// UART Testbench - EDA Playground (FIXED v2)
// Copy to LEFT pane (testbench.sv)
//=============================================================================

`timescale 1ns/1ps

module tb_uart;
    
    //=========================================================================
    // Parameters & Signals
    //=========================================================================
    parameter BAUD_DIV = 16;  // Use 16 clocks per bit for reliable timing
    parameter CLK_PERIOD = 10;  // 100MHz clock
    
    logic        clk, rst_n;
    logic [15:0] baud_div;
    logic [1:0]  parity_mode;  // 0=none, 1=even, 2=odd
    logic        stop_bits;    // 0=1 stop, 1=2 stop
    logic [7:0]  tx_data;
    logic        tx_valid;
    logic        tx_ready;
    logic        tx_done;
    logic [7:0]  rx_data;
    logic        rx_valid;
    logic        rx_error;
    logic        uart_txd;
    logic        uart_rxd;
    
    // Loopback connection
    assign uart_rxd = uart_txd;
    
    // Test tracking
    int pass_cnt = 0;
    int fail_cnt = 0;
    int test_num = 0;
    
    //=========================================================================
    // DUT
    //=========================================================================
    uart_top dut (.*);
    
    //=========================================================================
    // Clock Generation
    //=========================================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    //=========================================================================
    // Task: Reset DUT
    //=========================================================================
    task reset_dut();
        rst_n = 0;
        tx_valid = 0;
        tx_data = 0;
        baud_div = BAUD_DIV;
        parity_mode = 0;
        stop_bits = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);
    endtask
    
    //=========================================================================
    // Task: Send byte and wait for reception
    //=========================================================================
    task automatic send_and_verify(
        input [7:0] data,
        input [1:0] parity,
        input       stop2,
        output bit  result
    );
        int timeout;
        
        // Setup config
        parity_mode = parity;
        stop_bits = stop2;
        
        @(posedge clk);
        
        // Wait for TX ready
        timeout = 0;
        while (!tx_ready && timeout < 1000) begin
            @(posedge clk);
            timeout++;
        end
        
        if (timeout >= 1000) begin
            $display("[FAIL] Test %0d: TX not ready (timeout), data=0x%02h", test_num, data);
            result = 0;
            return;
        end
        
        // Start transmission
        tx_data = data;
        tx_valid = 1;
        @(posedge clk);
        tx_valid = 0;
        
        // Calculate timeout: start(1) + data(8) + parity(0/1) + stop(1/2) bits
        // Each bit = BAUD_DIV clocks, add margin
        timeout = 0;
        while (!rx_valid && timeout < (20 * BAUD_DIV)) begin
            @(posedge clk);
            timeout++;
        end
        
        if (!rx_valid) begin
            $display("[FAIL] Test %0d: No RX valid, data=0x%02h (waited %0d clocks)", 
                     test_num, data, timeout);
            result = 0;
            return;
        end
        
        // Verify received data
        if (rx_data !== data) begin
            $display("[FAIL] Test %0d: Data mismatch! TX=0x%02h, RX=0x%02h", 
                     test_num, data, rx_data);
            result = 0;
            return;
        end
        
        if (rx_error) begin
            $display("[FAIL] Test %0d: RX error flag set, data=0x%02h", test_num, data);
            result = 0;
            return;
        end
        
        $display("[PASS] Test %0d: TX=0x%02h, RX=0x%02h, parity=%0d, stop=%0d", 
                 test_num, data, rx_data, parity, stop2);
        result = 1;
    endtask
    
    //=========================================================================
    // Main Test
    //=========================================================================
    initial begin
        bit result;
        
        $display("");
        $display("=".repeat(60));
        $display("         UART VERIFICATION - EDA PLAYGROUND");
        $display("=".repeat(60));
        $display("BAUD_DIV = %0d clocks per bit", BAUD_DIV);
        $display("");
        
        // Initialize
        reset_dut();
        
        //=====================================================================
        // Test 1: Basic pattern tests (no parity, 1 stop)
        //=====================================================================
        $display("-".repeat(40));
        $display("TEST GROUP 1: Basic Patterns (No Parity)");
        $display("-".repeat(40));
        
        // Test alternating bits
        foreach ({8'hAA, 8'h55, 8'hA5, 8'h5A}[i]) begin
            test_num++;
            send_and_verify({8'hAA, 8'h55, 8'hA5, 8'h5A}[i], 0, 0, result);
            if (result) pass_cnt++; else fail_cnt++;
        end
        
        // Test all zeros and all ones
        test_num++;
        send_and_verify(8'h00, 0, 0, result);
        if (result) pass_cnt++; else fail_cnt++;
        
        test_num++;
        send_and_verify(8'hFF, 0, 0, result);
        if (result) pass_cnt++; else fail_cnt++;
        
        // Sequential values
        for (int i = 0; i < 8; i++) begin
            test_num++;
            send_and_verify(i, 0, 0, result);
            if (result) pass_cnt++; else fail_cnt++;
        end
        
        //=====================================================================
        // Test 2: Even parity tests
        //=====================================================================
        $display("-".repeat(40));
        $display("TEST GROUP 2: Even Parity");
        $display("-".repeat(40));
        
        // Various patterns with even parity
        foreach ({8'h00, 8'hFF, 8'hAA, 8'h55, 8'h0F, 8'hF0, 8'h12, 8'h34}[i]) begin
            test_num++;
            send_and_verify({8'h00, 8'hFF, 8'hAA, 8'h55, 8'h0F, 8'hF0, 8'h12, 8'h34}[i], 
                           1, 0, result);
            if (result) pass_cnt++; else fail_cnt++;
        end
        
        //=====================================================================
        // Test 3: Odd parity tests
        //=====================================================================
        $display("-".repeat(40));
        $display("TEST GROUP 3: Odd Parity");
        $display("-".repeat(40));
        
        // Various patterns with odd parity
        foreach ({8'h00, 8'hFF, 8'hAA, 8'h55, 8'h77, 8'h88, 8'hCD, 8'hEF}[i]) begin
            test_num++;
            send_and_verify({8'h00, 8'hFF, 8'hAA, 8'h55, 8'h77, 8'h88, 8'hCD, 8'hEF}[i], 
                           2, 0, result);
            if (result) pass_cnt++; else fail_cnt++;
        end
        
        //=====================================================================
        // Test 4: Two stop bits
        //=====================================================================
        $display("-".repeat(40));
        $display("TEST GROUP 4: Two Stop Bits");
        $display("-".repeat(40));
        
        // No parity, 2 stop bits
        foreach ({8'hDE, 8'hAD, 8'hBE, 8'hEF}[i]) begin
            test_num++;
            send_and_verify({8'hDE, 8'hAD, 8'hBE, 8'hEF}[i], 0, 1, result);
            if (result) pass_cnt++; else fail_cnt++;
        end
        
        // Even parity, 2 stop bits
        foreach ({8'h12, 8'h34}[i]) begin
            test_num++;
            send_and_verify({8'h12, 8'h34}[i], 1, 1, result);
            if (result) pass_cnt++; else fail_cnt++;
        end
        
        // Odd parity, 2 stop bits
        foreach ({8'h56, 8'h78}[i]) begin
            test_num++;
            send_and_verify({8'h56, 8'h78}[i], 2, 1, result);
            if (result) pass_cnt++; else fail_cnt++;
        end
        
        //=====================================================================
        // Test 5: Random values
        //=====================================================================
        $display("-".repeat(40));
        $display("TEST GROUP 5: Random Data");
        $display("-".repeat(40));
        
        for (int i = 0; i < 10; i++) begin
            test_num++;
            send_and_verify($urandom_range(0, 255), $urandom_range(0, 2), 
                           $urandom_range(0, 1), result);
            if (result) pass_cnt++; else fail_cnt++;
        end
        
        //=====================================================================
        // Final Summary
        //=====================================================================
        $display("");
        $display("=".repeat(60));
        $display("                    TEST SUMMARY");
        $display("=".repeat(60));
        $display("  Total Tests: %0d", test_num);
        $display("  PASSED:      %0d", pass_cnt);
        $display("  FAILED:      %0d", fail_cnt);
        $display("=".repeat(60));
        
        if (fail_cnt == 0) begin
            $display("");
            $display("  *** ALL TESTS PASSED! ***");
            $display("");
        end else begin
            $display("");
            $display("  *** SOME TESTS FAILED - CHECK OUTPUT ABOVE ***");
            $display("");
        end
        
        $display("=".repeat(60));
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #500000;  // 500us total timeout
        $display("");
        $display("*** GLOBAL TIMEOUT - SIMULATION TOOK TOO LONG ***");
        $display("Completed %0d tests before timeout", test_num);
        $finish;
    end
    
endmodule
