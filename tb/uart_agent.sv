//-----------------------------------------------------------------------------
// UART Agent
// Groups driver, monitor, and sequencer
//-----------------------------------------------------------------------------

class uart_agent extends uvm_agent;
    `uvm_component_utils(uart_agent)
    
    // Components
    uart_driver     driver;
    uart_monitor    monitor;
    uvm_sequencer #(uart_seq_item) sequencer;
    
    // Analysis port (passthrough from monitor)
    uvm_analysis_port #(uart_seq_item) tx_ap;
    uvm_analysis_port #(uart_seq_item) rx_ap;
    
    function new(string name = "uart_agent", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Always create monitor
        monitor = uart_monitor::type_id::create("monitor", this);
        
        // Create driver and sequencer only if active
        if (get_is_active() == UVM_ACTIVE) begin
            driver = uart_driver::type_id::create("driver", this);
            sequencer = uvm_sequencer#(uart_seq_item)::type_id::create("sequencer", this);
        end
        
        // Create analysis ports
        tx_ap = new("tx_ap", this);
        rx_ap = new("rx_ap", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect driver to sequencer
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
        
        // Connect analysis ports
        monitor.tx_ap.connect(tx_ap);
        monitor.rx_ap.connect(rx_ap);
    endfunction
    
endclass
