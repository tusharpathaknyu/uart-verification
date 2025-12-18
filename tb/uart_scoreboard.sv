//-----------------------------------------------------------------------------
// UART Scoreboard
// Compares TX data with RX data for loopback verification
//-----------------------------------------------------------------------------

class uart_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(uart_scoreboard)
    
    // Analysis FIFOs
    uvm_tlm_analysis_fifo #(uart_seq_item) tx_fifo;
    uvm_tlm_analysis_fifo #(uart_seq_item) rx_fifo;
    
    // Statistics
    int tx_count = 0;
    int rx_count = 0;
    int match_count = 0;
    int mismatch_count = 0;
    int error_count = 0;
    
    function new(string name = "uart_scoreboard", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tx_fifo = new("tx_fifo", this);
        rx_fifo = new("rx_fifo", this);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        uart_seq_item tx_item, rx_item;
        
        forever begin
            // Wait for both TX and RX items
            fork
                tx_fifo.get(tx_item);
                rx_fifo.get(rx_item);
            join
            
            tx_count++;
            rx_count++;
            
            compare_items(tx_item, rx_item);
        end
    endtask
    
    virtual function void compare_items(uart_seq_item tx_item, uart_seq_item rx_item);
        bit pass = 1;
        
        // Check for RX errors
        if (rx_item.rx_error) begin
            error_count++;
            `uvm_error(get_type_name(), 
                $sformatf("RX Error detected! TX=0x%02h", tx_item.tx_data))
            return;
        end
        
        // Compare data
        if (tx_item.tx_data !== rx_item.rx_data) begin
            pass = 0;
            `uvm_error(get_type_name(), 
                $sformatf("DATA MISMATCH! TX=0x%02h RX=0x%02h", 
                          tx_item.tx_data, rx_item.rx_data))
        end
        
        if (pass) begin
            match_count++;
            `uvm_info(get_type_name(), 
                $sformatf("MATCH: TX=0x%02h RX=0x%02h", tx_item.tx_data, rx_item.rx_data), 
                UVM_HIGH)
        end else begin
            mismatch_count++;
        end
    endfunction
    
    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "========== SCOREBOARD REPORT ==========", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("TX Transactions  : %0d", tx_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("RX Transactions  : %0d", rx_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Matches          : %0d", match_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Mismatches       : %0d", mismatch_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("RX Errors        : %0d", error_count), UVM_LOW)
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        
        if (mismatch_count > 0 || error_count > 0) begin
            `uvm_error(get_type_name(), "TEST FAILED - Mismatches or errors detected!")
        end else if (match_count > 0) begin
            `uvm_info(get_type_name(), "TEST PASSED - All data matched!", UVM_LOW)
        end
    endfunction
    
endclass
