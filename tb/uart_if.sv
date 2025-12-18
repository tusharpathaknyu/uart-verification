//-----------------------------------------------------------------------------
// UART Interface Definition
//-----------------------------------------------------------------------------

interface uart_if #(
    parameter DATA_WIDTH = 8
)(
    input logic clk,
    input logic rst_n
);
    
    // Configuration signals
    logic [31:0]            baud_rate;
    logic [1:0]             parity_mode;
    logic                   stop_bits;
    
    // TX interface
    logic [DATA_WIDTH-1:0]  tx_data;
    logic                   tx_valid;
    logic                   tx_ready;
    logic                   tx_done;
    
    // RX interface
    logic [DATA_WIDTH-1:0]  rx_data;
    logic                   rx_valid;
    logic                   rx_error;
    
    // Serial interface
    logic                   uart_tx;
    logic                   uart_rx;
    
    // Clocking blocks for synchronization
    clocking driver_cb @(posedge clk);
        default input #1 output #1;
        output tx_data;
        output tx_valid;
        input  tx_ready;
        input  tx_done;
        output baud_rate;
        output parity_mode;
        output stop_bits;
    endclocking
    
    clocking monitor_cb @(posedge clk);
        default input #1 output #1;
        input tx_data;
        input tx_valid;
        input tx_ready;
        input tx_done;
        input rx_data;
        input rx_valid;
        input rx_error;
        input uart_tx;
        input uart_rx;
        input baud_rate;
        input parity_mode;
        input stop_bits;
    endclocking
    
    // Modports
    modport DUT (
        input  clk, rst_n,
        input  baud_rate, parity_mode, stop_bits,
        input  tx_data, tx_valid,
        output tx_ready, tx_done,
        output rx_data, rx_valid, rx_error,
        output uart_tx,
        input  uart_rx
    );
    
    modport DRIVER (
        clocking driver_cb,
        input clk, rst_n
    );
    
    modport MONITOR (
        clocking monitor_cb,
        input clk, rst_n
    );

endinterface
