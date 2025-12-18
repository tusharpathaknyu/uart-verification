//=============================================================================
// UART Testbench - EDA Playground (Compatible Version)
// Copy to LEFT pane (testbench.sv)
//=============================================================================

`timescale 1ns/1ps

module tb_uart;
    
    parameter BAUD_DIV = 16;
    parameter CLK_PERIOD = 10;
    
    reg         clk, rst_n;
    reg  [15:0] baud_div;
    reg  [1:0]  parity_mode;
    reg         stop_bits;
    reg  [7:0]  tx_data;
    reg         tx_valid;
    wire        tx_ready;
    wire        tx_done;
    wire [7:0]  rx_data;
    wire        rx_valid;
    wire        rx_error;
    wire        uart_txd;
    wire        uart_rxd;
    
    assign uart_rxd = uart_txd;
    
    integer pass_cnt;
    integer fail_cnt;
    integer test_num;
    integer timeout;
    
    uart_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .baud_div(baud_div),
        .parity_mode(parity_mode),
        .stop_bits(stop_bits),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .tx_done(tx_done),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_error(rx_error),
        .uart_txd(uart_txd),
        .uart_rxd(uart_rxd)
    );
    
    // Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Main test
    initial begin
        pass_cnt = 0;
        fail_cnt = 0;
        test_num = 0;
        
        // Reset
        rst_n = 0;
        tx_valid = 0;
        tx_data = 0;
        baud_div = BAUD_DIV;
        parity_mode = 0;
        stop_bits = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);
        
        $display("");
        $display("============================================================");
        $display("         UART VERIFICATION - EDA PLAYGROUND");
        $display("============================================================");
        $display("BAUD_DIV = %0d clocks per bit", BAUD_DIV);
        $display("");
        
        // Test Group 1: Basic patterns (no parity, 1 stop)
        $display("----------------------------------------");
        $display("TEST GROUP 1: Basic Patterns (No Parity)");
        $display("----------------------------------------");
        
        run_test(8'hAA, 0, 0);
        run_test(8'h55, 0, 0);
        run_test(8'hA5, 0, 0);
        run_test(8'h5A, 0, 0);
        run_test(8'h00, 0, 0);
        run_test(8'hFF, 0, 0);
        run_test(8'h01, 0, 0);
        run_test(8'h02, 0, 0);
        run_test(8'h04, 0, 0);
        run_test(8'h08, 0, 0);
        
        // Test Group 2: Even parity
        $display("----------------------------------------");
        $display("TEST GROUP 2: Even Parity");
        $display("----------------------------------------");
        
        run_test(8'h00, 1, 0);
        run_test(8'hFF, 1, 0);
        run_test(8'hAA, 1, 0);
        run_test(8'h55, 1, 0);
        run_test(8'h0F, 1, 0);
        run_test(8'hF0, 1, 0);
        
        // Test Group 3: Odd parity
        $display("----------------------------------------");
        $display("TEST GROUP 3: Odd Parity");
        $display("----------------------------------------");
        
        run_test(8'h00, 2, 0);
        run_test(8'hFF, 2, 0);
        run_test(8'hAA, 2, 0);
        run_test(8'h55, 2, 0);
        run_test(8'h77, 2, 0);
        run_test(8'h88, 2, 0);
        
        // Test Group 4: Two stop bits
        $display("----------------------------------------");
        $display("TEST GROUP 4: Two Stop Bits");
        $display("----------------------------------------");
        
        run_test(8'hDE, 0, 1);
        run_test(8'hAD, 0, 1);
        run_test(8'hBE, 1, 1);
        run_test(8'hEF, 2, 1);
        
        // Test Group 5: More patterns
        $display("----------------------------------------");
        $display("TEST GROUP 5: Additional Patterns");
        $display("----------------------------------------");
        
        run_test(8'h12, 0, 0);
        run_test(8'h34, 1, 0);
        run_test(8'h56, 2, 0);
        run_test(8'h78, 0, 1);
        run_test(8'h9A, 1, 1);
        run_test(8'hBC, 2, 1);
        
        // Summary
        $display("");
        $display("============================================================");
        $display("                    TEST SUMMARY");
        $display("============================================================");
        $display("  Total Tests: %0d", test_num);
        $display("  PASSED:      %0d", pass_cnt);
        $display("  FAILED:      %0d", fail_cnt);
        $display("============================================================");
        
        if (fail_cnt == 0) begin
            $display("");
            $display("  *** ALL TESTS PASSED! ***");
            $display("");
        end else begin
            $display("");
            $display("  *** SOME TESTS FAILED - CHECK OUTPUT ABOVE ***");
            $display("");
        end
        
        $display("============================================================");
        $finish;
    end
    
    // Test task
    task run_test;
        input [7:0] data;
        input [1:0] parity;
        input       stop2;
        begin
            test_num = test_num + 1;
            parity_mode = parity;
            stop_bits = stop2;
            
            @(posedge clk);
            
            // Wait for TX ready
            timeout = 0;
            while (!tx_ready && timeout < 1000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            
            if (timeout >= 1000) begin
                $display("[FAIL] Test %0d: TX not ready, data=0x%02h", test_num, data);
                fail_cnt = fail_cnt + 1;
            end else begin
                // Send data
                tx_data = data;
                tx_valid = 1;
                @(posedge clk);
                tx_valid = 0;
                
                // Wait for RX valid
                timeout = 0;
                while (!rx_valid && timeout < 500) begin
                    @(posedge clk);
                    timeout = timeout + 1;
                end
                
                if (!rx_valid) begin
                    $display("[FAIL] Test %0d: No RX valid, TX=0x%02h", test_num, data);
                    fail_cnt = fail_cnt + 1;
                end else if (rx_data !== data) begin
                    $display("[FAIL] Test %0d: Mismatch TX=0x%02h RX=0x%02h", test_num, data, rx_data);
                    fail_cnt = fail_cnt + 1;
                end else if (rx_error) begin
                    $display("[FAIL] Test %0d: RX error, data=0x%02h", test_num, data);
                    fail_cnt = fail_cnt + 1;
                end else begin
                    $display("[PASS] Test %0d: TX=0x%02h RX=0x%02h p=%0d s=%0d", 
                             test_num, data, rx_data, parity, stop2);
                    pass_cnt = pass_cnt + 1;
                end
            end
        end
    endtask
    
    // Timeout
    initial begin
        #500000;
        $display("*** TIMEOUT ***");
        $finish;
    end
    
endmodule
