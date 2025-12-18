//-----------------------------------------------------------------------------
// UART Driver
// Drives stimulus to the DUT
//-----------------------------------------------------------------------------

class uart_driver extends uvm_driver #(uart_seq_item);
    `uvm_component_utils(uart_driver)
    
    // Virtual interface
    virtual uart_if vif;
    
    // Configuration
    int clk_freq = 50_000_000;
    
    function new(string name = "uart_driver", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "Virtual interface not found in config db")
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        uart_seq_item item;
        
        // Initialize outputs
        vif.driver_cb.tx_data <= 8'h00;
        vif.driver_cb.tx_valid <= 1'b0;
        vif.driver_cb.baud_rate <= 115200;
        vif.driver_cb.parity_mode <= 2'b00;
        vif.driver_cb.stop_bits <= 1'b0;
        
        // Wait for reset
        @(posedge vif.rst_n);
        repeat(5) @(posedge vif.clk);
        
        forever begin
            seq_item_port.get_next_item(item);
            drive_item(item);
            seq_item_port.item_done();
        end
    endtask
    
    virtual task drive_item(uart_seq_item item);
        int bit_period;
        int total_bits;
        
        `uvm_info(get_type_name(), $sformatf("Driving: %s", item.convert2string()), UVM_HIGH)
        
        // Apply configuration
        @(vif.driver_cb);
        vif.driver_cb.baud_rate <= item.baud_rate;
        vif.driver_cb.parity_mode <= item.parity_mode;
        vif.driver_cb.stop_bits <= item.stop_bits;
        
        // Wait for configuration to settle
        repeat(2) @(vif.driver_cb);
        
        // Apply delay if specified
        if (item.delay_cycles > 0) begin
            repeat(item.delay_cycles) @(vif.driver_cb);
        end
        
        // Wait for TX ready
        while (!vif.driver_cb.tx_ready) begin
            @(vif.driver_cb);
        end
        
        // Drive data
        vif.driver_cb.tx_data <= item.tx_data;
        vif.driver_cb.tx_valid <= 1'b1;
        @(vif.driver_cb);
        vif.driver_cb.tx_valid <= 1'b0;
        
        // Calculate wait time
        // Total bits = 1 start + 8 data + parity? + stop bits
        total_bits = 1 + 8 + (item.parity_mode != 0 ? 1 : 0) + (item.stop_bits ? 2 : 1);
        bit_period = clk_freq / item.baud_rate;
        
        // Wait for transmission to complete (with some margin)
        repeat(total_bits * bit_period + 100) @(vif.driver_cb);
        
        `uvm_info(get_type_name(), "Drive complete", UVM_HIGH)
    endtask
    
endclass
