//-----------------------------------------------------------------------------
// UART Receiver Module
// Simple UART RX with configurable baud rate, parity, and stop bits
//-----------------------------------------------------------------------------

module uart_rx #(
    parameter CLK_FREQ   = 50_000_000,  // System clock frequency
    parameter DATA_WIDTH = 8            // Data width (typically 8)
)(
    input  logic                    clk,
    input  logic                    rst_n,
    
    // Configuration
    input  logic [31:0]             baud_rate,      // Baud rate (9600, 115200, etc.)
    input  logic [1:0]              parity_mode,    // 0: None, 1: Even, 2: Odd
    input  logic                    stop_bits,      // 0: 1 stop bit, 1: 2 stop bits
    
    // Data interface
    output logic [DATA_WIDTH-1:0]   rx_data,        // Received data
    output logic                    rx_valid,       // Data valid signal
    output logic                    rx_error,       // Error flag (parity/framing)
    
    // UART input
    input  logic                    uart_rx         // Serial RX input
);

    // State machine states
    typedef enum logic [2:0] {
        IDLE      = 3'b000,
        START_BIT = 3'b001,
        DATA_BITS = 3'b010,
        PARITY    = 3'b011,
        STOP_BIT1 = 3'b100,
        STOP_BIT2 = 3'b101
    } state_t;
    
    state_t state, next_state;
    
    // Internal signals
    logic [31:0] baud_counter;
    logic [31:0] baud_tick_count;
    logic        baud_tick;
    logic        baud_tick_half;
    logic [2:0]  bit_counter;
    logic [DATA_WIDTH-1:0] rx_shift_reg;
    logic        parity_bit;
    logic        parity_error;
    logic        framing_error;
    
    // Synchronize RX input (metastability protection)
    logic        rx_sync1, rx_sync2;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= uart_rx;
            rx_sync2 <= rx_sync1;
        end
    end
    
    // Calculate baud tick count
    assign baud_tick_count = CLK_FREQ / baud_rate;
    
    // Baud rate generator - samples at middle of bit period
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_counter <= '0;
            baud_tick <= 1'b0;
            baud_tick_half <= 1'b0;
        end else begin
            if (state == IDLE) begin
                baud_counter <= '0;
                baud_tick <= 1'b0;
                baud_tick_half <= 1'b0;
            end else begin
                // Half tick for sampling at middle of bit
                if (baud_counter == (baud_tick_count >> 1)) begin
                    baud_tick_half <= 1'b1;
                end else begin
                    baud_tick_half <= 1'b0;
                end
                
                // Full tick for bit period
                if (baud_counter >= baud_tick_count - 1) begin
                    baud_counter <= '0;
                    baud_tick <= 1'b1;
                end else begin
                    baud_counter <= baud_counter + 1;
                    baud_tick <= 1'b0;
                end
            end
        end
    end
    
    // State machine - sequential
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // State machine - combinational
    always_comb begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (!rx_sync2)  // Start bit detected (low)
                    next_state = START_BIT;
            end
            
            START_BIT: begin
                if (baud_tick_half) begin
                    if (!rx_sync2)  // Confirm start bit at middle
                        next_state = DATA_BITS;
                    else
                        next_state = IDLE;  // False start
                end
            end
            
            DATA_BITS: begin
                if (baud_tick && bit_counter == DATA_WIDTH - 1) begin
                    if (parity_mode != 2'b00)
                        next_state = PARITY;
                    else
                        next_state = STOP_BIT1;
                end
            end
            
            PARITY: begin
                if (baud_tick)
                    next_state = STOP_BIT1;
            end
            
            STOP_BIT1: begin
                if (baud_tick) begin
                    if (stop_bits)
                        next_state = STOP_BIT2;
                    else
                        next_state = IDLE;
                end
            end
            
            STOP_BIT2: begin
                if (baud_tick)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Bit counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= '0;
        end else begin
            if (state == IDLE || state == START_BIT)
                bit_counter <= '0;
            else if (state == DATA_BITS && baud_tick)
                bit_counter <= bit_counter + 1;
        end
    end
    
    // RX shift register - sample at middle of bit period
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift_reg <= '0;
        end else begin
            if (state == DATA_BITS && baud_tick_half)
                rx_shift_reg <= {rx_sync2, rx_shift_reg[DATA_WIDTH-1:1]};
        end
    end
    
    // Parity check
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_bit <= 1'b0;
            parity_error <= 1'b0;
        end else begin
            if (state == PARITY && baud_tick_half) begin
                parity_bit <= rx_sync2;
            end
            
            if (state == STOP_BIT1 && parity_mode != 2'b00) begin
                case (parity_mode)
                    2'b01: parity_error <= (^rx_shift_reg) != parity_bit;      // Even
                    2'b10: parity_error <= (~(^rx_shift_reg)) != parity_bit;   // Odd
                    default: parity_error <= 1'b0;
                endcase
            end else if (state == IDLE) begin
                parity_error <= 1'b0;
            end
        end
    end
    
    // Framing error check (stop bit should be high)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            framing_error <= 1'b0;
        end else begin
            if (state == STOP_BIT1 && baud_tick_half) begin
                framing_error <= !rx_sync2;  // Stop bit should be high
            end else if (state == IDLE) begin
                framing_error <= 1'b0;
            end
        end
    end
    
    // Output data and valid signal
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= '0;
            rx_valid <= 1'b0;
            rx_error <= 1'b0;
        end else begin
            if (state == STOP_BIT1 && baud_tick && !stop_bits) begin
                rx_data <= rx_shift_reg;
                rx_valid <= 1'b1;
                rx_error <= parity_error | framing_error;
            end else if (state == STOP_BIT2 && baud_tick) begin
                rx_data <= rx_shift_reg;
                rx_valid <= 1'b1;
                rx_error <= parity_error | framing_error;
            end else begin
                rx_valid <= 1'b0;
                rx_error <= 1'b0;
            end
        end
    end

endmodule
