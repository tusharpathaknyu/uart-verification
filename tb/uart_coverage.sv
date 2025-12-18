//-----------------------------------------------------------------------------
// UART Functional Coverage
// Collects coverage metrics for verification closure
//-----------------------------------------------------------------------------

class uart_coverage extends uvm_subscriber #(uart_seq_item);
    `uvm_component_utils(uart_coverage)
    
    // Transaction for sampling
    uart_seq_item item;
    
    // Coverage groups
    covergroup cfg_cg with function sample(uart_seq_item t);
        option.per_instance = 1;
        option.name = "cfg_coverage";
        
        // Baud rate coverage
        baud_cp: coverpoint t.baud_rate {
            bins b9600   = {9600};
            bins b19200  = {19200};
            bins b38400  = {38400};
            bins b57600  = {57600};
            bins b115200 = {115200};
        }
        
        // Parity mode coverage
        parity_cp: coverpoint t.parity_mode {
            bins none = {0};
            bins even = {1};
            bins odd  = {2};
        }
        
        // Stop bits coverage
        stop_cp: coverpoint t.stop_bits {
            bins one_bit  = {0};
            bins two_bits = {1};
        }
        
        // Cross coverage - baud x parity
        baud_x_parity: cross baud_cp, parity_cp {
            option.weight = 2;
        }
        
        // Cross coverage - baud x stop
        baud_x_stop: cross baud_cp, stop_cp {
            option.weight = 2;
        }
        
        // Cross coverage - parity x stop
        parity_x_stop: cross parity_cp, stop_cp {
            option.weight = 1;
        }
        
        // Full cross coverage
        full_cross: cross baud_cp, parity_cp, stop_cp {
            option.weight = 3;
        }
    endgroup
    
    covergroup data_cg with function sample(uart_seq_item t);
        option.per_instance = 1;
        option.name = "data_coverage";
        
        // TX data value coverage
        tx_data_cp: coverpoint t.tx_data {
            bins zero     = {8'h00};
            bins all_ones = {8'hFF};
            bins low      = {[8'h01:8'h3F]};
            bins mid      = {[8'h40:8'hBF]};
            bins high     = {[8'hC0:8'hFE]};
        }
        
        // Special patterns
        tx_pattern_cp: coverpoint t.tx_data {
            bins alternating_01 = {8'h55};
            bins alternating_10 = {8'hAA};
            bins nibble_low     = {8'h0F};
            bins nibble_high    = {8'hF0};
        }
        
        // Single bit patterns
        tx_single_bit_cp: coverpoint t.tx_data {
            bins bit0 = {8'h01};
            bins bit1 = {8'h02};
            bins bit2 = {8'h04};
            bins bit3 = {8'h08};
            bins bit4 = {8'h10};
            bins bit5 = {8'h20};
            bins bit6 = {8'h40};
            bins bit7 = {8'h80};
        }
        
        // Parity implications (even parity = even number of 1s)
        tx_parity_even_cp: coverpoint $countones(t.tx_data) {
            bins even_ones = {0, 2, 4, 6, 8};
            bins odd_ones  = {1, 3, 5, 7};
        }
    endgroup
    
    covergroup error_cg with function sample(uart_seq_item t);
        option.per_instance = 1;
        option.name = "error_coverage";
        
        // RX error coverage
        rx_error_cp: coverpoint t.rx_error {
            bins no_error = {0};
            bins error    = {1};
        }
        
        // Error with different configs
        error_x_parity: cross rx_error_cp, t.parity_mode {
            ignore_bins no_parity_error = binsof(t.parity_mode) intersect {0} &&
                                          binsof(rx_error_cp) intersect {1};
        }
    endgroup
    
    covergroup transition_cg with function sample(logic [7:0] prev_data, logic [7:0] curr_data);
        option.per_instance = 1;
        option.name = "transition_coverage";
        
        // Data transitions
        prev_cp: coverpoint prev_data {
            bins low  = {[0:85]};
            bins mid  = {[86:170]};
            bins high = {[171:255]};
        }
        
        curr_cp: coverpoint curr_data {
            bins low  = {[0:85]};
            bins mid  = {[86:170]};
            bins high = {[171:255]};
        }
        
        transition_cross: cross prev_cp, curr_cp;
    endgroup
    
    // Previous data for transition coverage
    logic [7:0] prev_tx_data;
    bit first_transaction = 1;
    
    function new(string name = "uart_coverage", uvm_component parent);
        super.new(name, parent);
        cfg_cg = new();
        data_cg = new();
        error_cg = new();
        transition_cg = new();
    endfunction
    
    virtual function void write(uart_seq_item t);
        // Sample coverage groups
        cfg_cg.sample(t);
        data_cg.sample(t);
        error_cg.sample(t);
        
        // Sample transition coverage
        if (!first_transaction) begin
            transition_cg.sample(prev_tx_data, t.tx_data);
        end
        prev_tx_data = t.tx_data;
        first_transaction = 0;
        
        `uvm_info(get_type_name(), 
            $sformatf("Coverage sampled: %s", t.convert2string()), UVM_HIGH)
    endfunction
    
    virtual function void report_phase(uvm_phase phase);
        real cfg_cov, data_cov, error_cov, trans_cov, total_cov;
        
        cfg_cov = cfg_cg.get_coverage();
        data_cov = data_cg.get_coverage();
        error_cov = error_cg.get_coverage();
        trans_cov = transition_cg.get_coverage();
        total_cov = (cfg_cov + data_cov + error_cov + trans_cov) / 4.0;
        
        `uvm_info(get_type_name(), "========== COVERAGE REPORT ==========", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Configuration Coverage : %0.2f%%", cfg_cov), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Data Coverage          : %0.2f%%", data_cov), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Error Coverage         : %0.2f%%", error_cov), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Transition Coverage    : %0.2f%%", trans_cov), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Total Coverage         : %0.2f%%", total_cov), UVM_LOW)
        `uvm_info(get_type_name(), "======================================", UVM_LOW)
        
        if (total_cov < 95.0) begin
            `uvm_warning(get_type_name(), 
                $sformatf("Coverage target (95%%) not met! Current: %0.2f%%", total_cov))
        end
    endfunction
    
endclass
