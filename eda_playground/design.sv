//=============================================================================
// UART Design - EDA Playground (FIXED v2)
// Copy to RIGHT pane (design.sv)
//=============================================================================

`timescale 1ns/1ps

//-----------------------------------------------------------------------------
// UART Transmitter
//-----------------------------------------------------------------------------
module uart_tx #(
    parameter DATA_WIDTH = 8
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [15:0]             baud_div,       // Clock cycles per bit
    input  logic [1:0]              parity_mode,    // 0: None, 1: Even, 2: Odd
    input  logic                    stop_bits,      // 0: 1 stop, 1: 2 stop
    input  logic [DATA_WIDTH-1:0]   tx_data,
    input  logic                    tx_valid,
    output logic                    tx_ready,
    output logic                    uart_tx,
    output logic                    tx_done
);

    typedef enum logic [2:0] {
        TX_IDLE, TX_START, TX_DATA, TX_PARITY, TX_STOP1, TX_STOP2
    } tx_state_t;
    
    tx_state_t state;
    
    logic [15:0] baud_cnt;
    logic [2:0]  bit_cnt;
    logic [DATA_WIDTH-1:0] shift_reg;
    logic        parity_bit;
    
    // Parity calculation
    assign parity_bit = (parity_mode == 2'b01) ? ^shift_reg :      // Even
                        (parity_mode == 2'b10) ? ~(^shift_reg) :   // Odd
                        1'b0;
    
    assign tx_ready = (state == TX_IDLE);
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= TX_IDLE;
            baud_cnt <= '0;
            bit_cnt <= '0;
            shift_reg <= '0;
            uart_tx <= 1'b1;
            tx_done <= 1'b0;
        end else begin
            tx_done <= 1'b0;
            
            case (state)
                TX_IDLE: begin
                    uart_tx <= 1'b1;
                    baud_cnt <= '0;
                    bit_cnt <= '0;
                    if (tx_valid) begin
                        shift_reg <= tx_data;
                        state <= TX_START;
                    end
                end
                
                TX_START: begin
                    uart_tx <= 1'b0;  // Start bit = 0
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= '0;
                        state <= TX_DATA;
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                TX_DATA: begin
                    uart_tx <= shift_reg[0];  // LSB first
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= '0;
                        shift_reg <= {1'b0, shift_reg[DATA_WIDTH-1:1]};
                        if (bit_cnt >= DATA_WIDTH - 1) begin
                            bit_cnt <= '0;
                            state <= (parity_mode != 0) ? TX_PARITY : TX_STOP1;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                TX_PARITY: begin
                    uart_tx <= parity_bit;
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= '0;
                        state <= TX_STOP1;
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                TX_STOP1: begin
                    uart_tx <= 1'b1;  // Stop bit = 1
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= '0;
                        if (stop_bits) begin
                            state <= TX_STOP2;
                        end else begin
                            tx_done <= 1'b1;
                            state <= TX_IDLE;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                TX_STOP2: begin
                    uart_tx <= 1'b1;
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= '0;
                        tx_done <= 1'b1;
                        state <= TX_IDLE;
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                default: state <= TX_IDLE;
            endcase
        end
    end
endmodule

//-----------------------------------------------------------------------------
// UART Receiver
//-----------------------------------------------------------------------------
module uart_rx #(
    parameter DATA_WIDTH = 8
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [15:0]             baud_div,
    input  logic [1:0]              parity_mode,
    input  logic                    stop_bits,
    output logic [DATA_WIDTH-1:0]   rx_data,
    output logic                    rx_valid,
    output logic                    rx_error,
    input  logic                    uart_rx
);

    typedef enum logic [2:0] {
        RX_IDLE, RX_START, RX_DATA, RX_PARITY, RX_STOP1, RX_STOP2
    } rx_state_t;
    
    rx_state_t state;
    
    logic [15:0] baud_cnt;
    logic [2:0]  bit_cnt;
    logic [DATA_WIDTH-1:0] shift_reg;
    logic        parity_bit;
    logic        parity_err;
    logic        frame_err;
    logic        rx_d;  // Single FF sync for simulation (minimal delay)
    
    // Simple 1-FF sync (for simulation with loopback)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) rx_d <= 1'b1;
        else rx_d <= uart_rx;
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= RX_IDLE;
            baud_cnt <= '0;
            bit_cnt <= '0;
            shift_reg <= '0;
            parity_bit <= 1'b0;
            parity_err <= 1'b0;
            frame_err <= 1'b0;
            rx_data <= '0;
            rx_valid <= 1'b0;
            rx_error <= 1'b0;
        end else begin
            rx_valid <= 1'b0;
            rx_error <= 1'b0;
            
            case (state)
                RX_IDLE: begin
                    baud_cnt <= '0;
                    bit_cnt <= '0;
                    parity_err <= 1'b0;
                    frame_err <= 1'b0;
                    if (!rx_d) begin  // Falling edge = start bit
                        state <= RX_START;
                    end
                end
                
                RX_START: begin
                    // Sample at middle of start bit to confirm
                    if (baud_cnt == (baud_div >> 1)) begin
                        if (!rx_d) begin
                            // Valid start bit, continue
                            baud_cnt <= baud_cnt + 1;
                        end else begin
                            // False start, go back to idle
                            state <= RX_IDLE;
                            baud_cnt <= '0;
                        end
                    end else if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= '0;
                        state <= RX_DATA;
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                RX_DATA: begin
                    // Sample at middle of each bit
                    if (baud_cnt == (baud_div >> 1)) begin
                        shift_reg <= {rx_d, shift_reg[DATA_WIDTH-1:1]};  // Shift in MSB
                    end
                    
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= '0;
                        if (bit_cnt >= DATA_WIDTH - 1) begin
                            bit_cnt <= '0;
                            state <= (parity_mode != 0) ? RX_PARITY : RX_STOP1;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                RX_PARITY: begin
                    if (baud_cnt == (baud_div >> 1)) begin
                        parity_bit <= rx_d;
                    end
                    
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= '0;
                        // Check parity
                        case (parity_mode)
                            2'b01: parity_err <= (^shift_reg) != parity_bit;  // Even
                            2'b10: parity_err <= (~(^shift_reg)) != parity_bit; // Odd
                            default: parity_err <= 1'b0;
                        endcase
                        state <= RX_STOP1;
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                RX_STOP1: begin
                    if (baud_cnt == (baud_div >> 1)) begin
                        frame_err <= !rx_d;  // Stop bit should be high
                    end
                    
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= '0;
                        if (stop_bits) begin
                            state <= RX_STOP2;
                        end else begin
                            rx_data <= shift_reg;
                            rx_valid <= 1'b1;
                            rx_error <= parity_err | frame_err;
                            state <= RX_IDLE;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                RX_STOP2: begin
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= '0;
                        rx_data <= shift_reg;
                        rx_valid <= 1'b1;
                        rx_error <= parity_err | frame_err;
                        state <= RX_IDLE;
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                default: state <= RX_IDLE;
            endcase
        end
    end
endmodule

//-----------------------------------------------------------------------------
// UART Top
//-----------------------------------------------------------------------------
module uart_top #(
    parameter DATA_WIDTH = 8
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [15:0]             baud_div,
    input  logic [1:0]              parity_mode,
    input  logic                    stop_bits,
    input  logic [DATA_WIDTH-1:0]   tx_data,
    input  logic                    tx_valid,
    output logic                    tx_ready,
    output logic                    tx_done,
    output logic [DATA_WIDTH-1:0]   rx_data,
    output logic                    rx_valid,
    output logic                    rx_error,
    output logic                    uart_txd,
    input  logic                    uart_rxd
);

    uart_tx #(.DATA_WIDTH(DATA_WIDTH)) u_tx (
        .clk(clk), .rst_n(rst_n), .baud_div(baud_div),
        .parity_mode(parity_mode), .stop_bits(stop_bits),
        .tx_data(tx_data), .tx_valid(tx_valid), .tx_ready(tx_ready),
        .uart_tx(uart_txd), .tx_done(tx_done)
    );
    
    uart_rx #(.DATA_WIDTH(DATA_WIDTH)) u_rx (
        .clk(clk), .rst_n(rst_n), .baud_div(baud_div),
        .parity_mode(parity_mode), .stop_bits(stop_bits),
        .rx_data(rx_data), .rx_valid(rx_valid), .rx_error(rx_error),
        .uart_rx(uart_rxd)
    );
endmodule
