//-----------------------------------------------------------------------------
// UART Testbench Top
// Top-level module instantiating DUT and testbench
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module uart_tb_top;
    
    import uvm_pkg::*;
    import uart_pkg::*;
    
    // Parameters
    parameter CLK_FREQ = 50_000_000;
    parameter CLK_PERIOD = 1_000_000_000 / CLK_FREQ;  // in ns
    
    // Signals
    logic clk;
    logic rst_n;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Reset generation
    initial begin
        rst_n = 0;
        repeat(10) @(posedge clk);
        rst_n = 1;
    end
    
    // Interface instance
    uart_if #(.DATA_WIDTH(8)) vif (
        .clk   (clk),
        .rst_n (rst_n)
    );
    
    // DUT instance (loopback: TX connected to RX)
    uart_top #(
        .CLK_FREQ   (CLK_FREQ),
        .DATA_WIDTH (8)
    ) dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .baud_rate   (vif.baud_rate),
        .parity_mode (vif.parity_mode),
        .stop_bits   (vif.stop_bits),
        .tx_data     (vif.tx_data),
        .tx_valid    (vif.tx_valid),
        .tx_ready    (vif.tx_ready),
        .tx_done     (vif.tx_done),
        .rx_data     (vif.rx_data),
        .rx_valid    (vif.rx_valid),
        .rx_error    (vif.rx_error),
        .uart_tx     (vif.uart_tx),
        .uart_rx     (vif.uart_rx)
    );
    
    // Loopback connection: TX output goes to RX input
    assign vif.uart_rx = vif.uart_tx;
    
    // UVM configuration and test start
    initial begin
        // Store interface in config database
        uvm_config_db#(virtual uart_if)::set(null, "*", "vif", vif);
        
        // Dump waveforms
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb_top);
        
        // Run test
        run_test();
    end
    
    // Timeout watchdog
    initial begin
        #100_000_000;  // 100ms timeout
        `uvm_fatal("TIMEOUT", "Simulation timeout!")
    end
    
endmodule
