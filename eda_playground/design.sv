//=============================================================================
// UART Design - EDA Playground (FIXED v3)
//=============================================================================

`timescale 1ns/1ps

//-----------------------------------------------------------------------------
// UART Transmitter
//-----------------------------------------------------------------------------
module uart_tx #(
    parameter DATA_WIDTH = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [15:0]              baud_div,
    input  wire [1:0]               parity_mode,
    input  wire                     stop_bits,
    input  wire [DATA_WIDTH-1:0]    tx_data,
    input  wire                     tx_valid,
    output reg                      tx_ready,
    output reg                      uart_tx,
    output reg                      tx_done
);

    localparam TX_IDLE   = 3'd0;
    localparam TX_START  = 3'd1;
    localparam TX_DATA   = 3'd2;
    localparam TX_PARITY = 3'd3;
    localparam TX_STOP1  = 3'd4;
    localparam TX_STOP2  = 3'd5;
    
    reg [2:0]  state;
    reg [15:0] baud_cnt;
    reg [2:0]  bit_cnt;
    reg [DATA_WIDTH-1:0] shift_reg;
    reg [DATA_WIDTH-1:0] tx_data_saved;  // Save data for parity calc
    wire parity_bit;
    
    // Parity: use saved data (not shifting register)
    assign parity_bit = (parity_mode == 2'b01) ? ^tx_data_saved :      // Even
                        (parity_mode == 2'b10) ? ~(^tx_data_saved) :   // Odd
                        1'b0;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= TX_IDLE;
            baud_cnt <= 0;
            bit_cnt <= 0;
            shift_reg <= 0;
            tx_data_saved <= 0;
            uart_tx <= 1;
            tx_done <= 0;
            tx_ready <= 1;
        end else begin
            tx_done <= 0;
            
            case (state)
                TX_IDLE: begin
                    uart_tx <= 1;
                    tx_ready <= 1;
                    baud_cnt <= 0;
                    bit_cnt <= 0;
                    if (tx_valid) begin
                        shift_reg <= tx_data;
                        tx_data_saved <= tx_data;
                        tx_ready <= 0;
                        state <= TX_START;
                    end
                end
                
                TX_START: begin
                    uart_tx <= 0;
                    tx_ready <= 0;
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= 0;
                        state <= TX_DATA;
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                TX_DATA: begin
                    uart_tx <= shift_reg[0];
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= 0;
                        shift_reg <= {1'b0, shift_reg[DATA_WIDTH-1:1]};
                        if (bit_cnt >= DATA_WIDTH - 1) begin
                            bit_cnt <= 0;
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
                        baud_cnt <= 0;
                        state <= TX_STOP1;
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                TX_STOP1: begin
                    uart_tx <= 1;
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= 0;
                        if (stop_bits) begin
                            state <= TX_STOP2;
                        end else begin
                            tx_done <= 1;
                            state <= TX_IDLE;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                TX_STOP2: begin
                    uart_tx <= 1;
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= 0;
                        tx_done <= 1;
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
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [15:0]              baud_div,
    input  wire [1:0]               parity_mode,
    input  wire                     stop_bits,
    output reg  [DATA_WIDTH-1:0]    rx_data,
    output reg                      rx_valid,
    output reg                      rx_error,
    input  wire                     uart_rx
);

    localparam RX_IDLE   = 3'd0;
    localparam RX_START  = 3'd1;
    localparam RX_DATA   = 3'd2;
    localparam RX_PARITY = 3'd3;
    localparam RX_STOP1  = 3'd4;
    localparam RX_STOP2  = 3'd5;
    
    reg [2:0]  state;
    reg [15:0] baud_cnt;
    reg [2:0]  bit_cnt;
    reg [DATA_WIDTH-1:0] shift_reg;
    reg        parity_rcvd;
    reg        parity_err;
    reg        frame_err;
    reg        rx_sync;
    
    // Synchronizer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) rx_sync <= 1;
        else rx_sync <= uart_rx;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= RX_IDLE;
            baud_cnt <= 0;
            bit_cnt <= 0;
            shift_reg <= 0;
            parity_rcvd <= 0;
            parity_err <= 0;
            frame_err <= 0;
            rx_data <= 0;
            rx_valid <= 0;
            rx_error <= 0;
        end else begin
            rx_valid <= 0;
            rx_error <= 0;
            
            case (state)
                RX_IDLE: begin
                    baud_cnt <= 0;
                    bit_cnt <= 0;
                    parity_err <= 0;
                    frame_err <= 0;
                    if (!rx_sync) begin
                        state <= RX_START;
                    end
                end
                
                RX_START: begin
                    if (baud_cnt == (baud_div >> 1)) begin
                        if (!rx_sync) begin
                            baud_cnt <= baud_cnt + 1;
                        end else begin
                            state <= RX_IDLE;
                            baud_cnt <= 0;
                        end
                    end else if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= 0;
                        state <= RX_DATA;
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                RX_DATA: begin
                    if (baud_cnt == (baud_div >> 1)) begin
                        shift_reg <= {rx_sync, shift_reg[DATA_WIDTH-1:1]};
                    end
                    
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= 0;
                        if (bit_cnt >= DATA_WIDTH - 1) begin
                            bit_cnt <= 0;
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
                        parity_rcvd <= rx_sync;
                    end
                    
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= 0;
                        state <= RX_STOP1;
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                RX_STOP1: begin
                    // Check parity NOW (after parity_rcvd is stable)
                    if (baud_cnt == 1) begin
                        case (parity_mode)
                            2'b01: parity_err <= (^shift_reg) != parity_rcvd;   // Even
                            2'b10: parity_err <= (~(^shift_reg)) != parity_rcvd; // Odd
                            default: parity_err <= 0;
                        endcase
                    end
                    
                    if (baud_cnt == (baud_div >> 1)) begin
                        frame_err <= !rx_sync;
                    end
                    
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= 0;
                        if (stop_bits) begin
                            state <= RX_STOP2;
                        end else begin
                            rx_data <= shift_reg;
                            rx_valid <= 1;
                            rx_error <= parity_err | frame_err;
                            state <= RX_IDLE;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                
                RX_STOP2: begin
                    if (baud_cnt >= baud_div - 1) begin
                        baud_cnt <= 0;
                        rx_data <= shift_reg;
                        rx_valid <= 1;
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
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [15:0]              baud_div,
    input  wire [1:0]               parity_mode,
    input  wire                     stop_bits,
    input  wire [DATA_WIDTH-1:0]    tx_data,
    input  wire                     tx_valid,
    output wire                     tx_ready,
    output wire                     tx_done,
    output wire [DATA_WIDTH-1:0]    rx_data,
    output wire                     rx_valid,
    output wire                     rx_error,
    output wire                     uart_txd,
    input  wire                     uart_rxd
);

    uart_tx #(.DATA_WIDTH(DATA_WIDTH)) u_tx (
        .clk(clk),
        .rst_n(rst_n),
        .baud_div(baud_div),
        .parity_mode(parity_mode),
        .stop_bits(stop_bits),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .uart_tx(uart_txd),
        .tx_done(tx_done)
    );
    
    uart_rx #(.DATA_WIDTH(DATA_WIDTH)) u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .baud_div(baud_div),
        .parity_mode(parity_mode),
        .stop_bits(stop_bits),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_error(rx_error),
        .uart_rx(uart_rxd)
    );
endmodule
