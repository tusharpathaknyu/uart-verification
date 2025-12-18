//-----------------------------------------------------------------------------
// UART Transmitter Module - BUGGY VERSION
// This version contains intentional bugs for verification demonstration
//
// INJECTED BUGS:
// BUG001: Off-by-one error in baud rate counter (line ~58)
// BUG002: Wrong parity calculation - uses XNOR instead of XOR for even (line ~68)
//-----------------------------------------------------------------------------

module uart_tx_buggy #(
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
    input  logic [DATA_WIDTH-1:0]   tx_data,        // Data to transmit
    input  logic                    tx_valid,       // Data valid signal
    output logic                    tx_ready,       // Ready to accept data
    
    // UART output
    output logic                    uart_tx,        // Serial TX output
    output logic                    tx_done         // Transmission complete
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
    logic [2:0]  bit_counter;
    logic [DATA_WIDTH-1:0] tx_shift_reg;
    logic        parity_bit;
    
    // Calculate baud tick count
    // Number of clock cycles per baud period
    assign baud_tick_count = CLK_FREQ / baud_rate;
    
    // Baud rate generator
    // BUG001: Off-by-one error - should be >= baud_tick_count - 1
    //         but using >= baud_tick_count (one extra cycle per bit)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_counter <= '0;
            baud_tick <= 1'b0;
        end else begin
            if (state == IDLE) begin
                baud_counter <= '0;
                baud_tick <= 1'b0;
            end else if (baud_counter >= baud_tick_count) begin  // BUG: should be baud_tick_count - 1
                baud_counter <= '0;
                baud_tick <= 1'b1;
            end else begin
                baud_counter <= baud_counter + 1;
                baud_tick <= 1'b0;
            end
        end
    end
    
    // Parity calculation
    // BUG002: Even parity uses XNOR (~^) instead of XOR (^)
    //         This inverts the parity bit for even parity mode
    always_comb begin
        case (parity_mode)
            2'b01:   parity_bit = ~(^tx_shift_reg);     // BUG: Should be ^tx_shift_reg for even parity
            2'b10:   parity_bit = ^tx_shift_reg;        // BUG: Should be ~(^tx_shift_reg) for odd parity
            default: parity_bit = 1'b0;                 // No parity
        endcase
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
                if (tx_valid)
                    next_state = START_BIT;
            end
            
            START_BIT: begin
                if (baud_tick)
                    next_state = DATA_BITS;
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
    
    // TX shift register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_reg <= '0;
        end else begin
            if (state == IDLE && tx_valid)
                tx_shift_reg <= tx_data;
            else if (state == DATA_BITS && baud_tick)
                tx_shift_reg <= {1'b0, tx_shift_reg[DATA_WIDTH-1:1]};
        end
    end
    
    // UART TX output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_tx <= 1'b1;  // Idle high
        end else begin
            case (state)
                IDLE:      uart_tx <= 1'b1;
                START_BIT: uart_tx <= 1'b0;
                DATA_BITS: uart_tx <= tx_shift_reg[0];
                PARITY:    uart_tx <= parity_bit;
                STOP_BIT1: uart_tx <= 1'b1;
                STOP_BIT2: uart_tx <= 1'b1;
                default:   uart_tx <= 1'b1;
            endcase
        end
    end
    
    // Output signals
    assign tx_ready = (state == IDLE);
    assign tx_done  = (state == STOP_BIT1 && !stop_bits && baud_tick) ||
                      (state == STOP_BIT2 && baud_tick);

endmodule
