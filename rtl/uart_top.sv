//-----------------------------------------------------------------------------
// UART Top Module
// Combines TX and RX with shared configuration
//-----------------------------------------------------------------------------

module uart_top #(
    parameter CLK_FREQ   = 50_000_000,  // System clock frequency
    parameter DATA_WIDTH = 8            // Data width (typically 8)
)(
    input  logic                    clk,
    input  logic                    rst_n,
    
    // Configuration
    input  logic [31:0]             baud_rate,      // Baud rate
    input  logic [1:0]              parity_mode,    // 0: None, 1: Even, 2: Odd
    input  logic                    stop_bits,      // 0: 1 stop bit, 1: 2 stop bits
    
    // TX interface
    input  logic [DATA_WIDTH-1:0]   tx_data,
    input  logic                    tx_valid,
    output logic                    tx_ready,
    output logic                    tx_done,
    
    // RX interface
    output logic [DATA_WIDTH-1:0]   rx_data,
    output logic                    rx_valid,
    output logic                    rx_error,
    
    // UART serial interface
    output logic                    uart_tx,
    input  logic                    uart_rx
);

    // TX instance
    uart_tx #(
        .CLK_FREQ   (CLK_FREQ),
        .DATA_WIDTH (DATA_WIDTH)
    ) u_uart_tx (
        .clk            (clk),
        .rst_n          (rst_n),
        .baud_rate      (baud_rate),
        .parity_mode    (parity_mode),
        .stop_bits      (stop_bits),
        .tx_data        (tx_data),
        .tx_valid       (tx_valid),
        .tx_ready       (tx_ready),
        .uart_tx        (uart_tx),
        .tx_done        (tx_done)
    );
    
    // RX instance
    uart_rx #(
        .CLK_FREQ   (CLK_FREQ),
        .DATA_WIDTH (DATA_WIDTH)
    ) u_uart_rx (
        .clk            (clk),
        .rst_n          (rst_n),
        .baud_rate      (baud_rate),
        .parity_mode    (parity_mode),
        .stop_bits      (stop_bits),
        .rx_data        (rx_data),
        .rx_valid       (rx_valid),
        .rx_error       (rx_error),
        .uart_rx        (uart_rx)
    );

endmodule
