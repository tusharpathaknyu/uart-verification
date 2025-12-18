//-----------------------------------------------------------------------------
// UART Monitor
// Monitors UART signals and creates transactions
//-----------------------------------------------------------------------------

class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)
    
    // Virtual interface
    virtual uart_if vif;
    
    // Analysis ports
    uvm_analysis_port #(uart_seq_item) tx_ap;  // TX transactions
    uvm_analysis_port #(uart_seq_item) rx_ap;  // RX transactions
    
    // Coverage enable
    bit enable_coverage = 1;
    
    function new(string name = "uart_monitor", uvm_component parent);
        super.new(name, parent);
        tx_ap = new("tx_ap", this);
        rx_ap = new("rx_ap", this);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "Virtual interface not found in config db")
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        fork
            monitor_tx();
            monitor_rx();
        join
    endtask
    
    // Monitor TX interface
    virtual task monitor_tx();
        uart_seq_item item;
        
        @(posedge vif.rst_n);
        
        forever begin
            @(vif.monitor_cb);
            
            // Detect tx_valid assertion
            if (vif.monitor_cb.tx_valid && vif.monitor_cb.tx_ready) begin
                item = uart_seq_item::type_id::create("tx_item");
                item.tx_data = vif.monitor_cb.tx_data;
                item.baud_rate = vif.monitor_cb.baud_rate;
                item.parity_mode = vif.monitor_cb.parity_mode;
                item.stop_bits = vif.monitor_cb.stop_bits;
                
                `uvm_info(get_type_name(), $sformatf("TX Monitor: %s", item.convert2string()), UVM_HIGH)
                tx_ap.write(item);
            end
        end
    endtask
    
    // Monitor RX interface
    virtual task monitor_rx();
        uart_seq_item item;
        
        @(posedge vif.rst_n);
        
        forever begin
            @(vif.monitor_cb);
            
            // Detect rx_valid assertion
            if (vif.monitor_cb.rx_valid) begin
                item = uart_seq_item::type_id::create("rx_item");
                item.rx_data = vif.monitor_cb.rx_data;
                item.rx_valid = vif.monitor_cb.rx_valid;
                item.rx_error = vif.monitor_cb.rx_error;
                item.baud_rate = vif.monitor_cb.baud_rate;
                item.parity_mode = vif.monitor_cb.parity_mode;
                item.stop_bits = vif.monitor_cb.stop_bits;
                
                `uvm_info(get_type_name(), 
                    $sformatf("RX Monitor: data=0x%02h error=%0b", item.rx_data, item.rx_error), 
                    UVM_HIGH)
                rx_ap.write(item);
            end
        end
    endtask
    
endclass
