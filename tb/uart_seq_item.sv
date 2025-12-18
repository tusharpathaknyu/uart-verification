//-----------------------------------------------------------------------------
// UART Sequence Item
// Transaction class for UART operations
//-----------------------------------------------------------------------------

class uart_seq_item extends uvm_sequence_item;
    
    // Configuration
    rand logic [31:0]   baud_rate;
    rand logic [1:0]    parity_mode;
    rand logic          stop_bits;
    
    // TX Data
    rand logic [7:0]    tx_data;
    
    // RX Data (for checking)
    logic [7:0]         rx_data;
    logic               rx_valid;
    logic               rx_error;
    
    // Control
    rand int unsigned   delay_cycles;
    
    // Constraints
    constraint c_baud_rate {
        baud_rate inside {9600, 19200, 38400, 57600, 115200};
    }
    
    constraint c_parity {
        parity_mode inside {[0:2]};
    }
    
    constraint c_stop_bits {
        stop_bits inside {0, 1};
    }
    
    constraint c_delay {
        delay_cycles inside {[0:100]};
    }
    
    // UVM automation macros
    `uvm_object_utils_begin(uart_seq_item)
        `uvm_field_int(baud_rate, UVM_ALL_ON)
        `uvm_field_int(parity_mode, UVM_ALL_ON)
        `uvm_field_int(stop_bits, UVM_ALL_ON)
        `uvm_field_int(tx_data, UVM_ALL_ON)
        `uvm_field_int(rx_data, UVM_ALL_ON)
        `uvm_field_int(rx_valid, UVM_ALL_ON)
        `uvm_field_int(rx_error, UVM_ALL_ON)
        `uvm_field_int(delay_cycles, UVM_ALL_ON)
    `uvm_object_utils_end
    
    // Constructor
    function new(string name = "uart_seq_item");
        super.new(name);
    endfunction
    
    // Convert to string for printing
    function string convert2string();
        return $sformatf("TX_DATA=0x%02h BAUD=%0d PARITY=%0d STOP=%0d",
                         tx_data, baud_rate, parity_mode, stop_bits);
    endfunction
    
endclass
