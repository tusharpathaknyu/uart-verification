//-----------------------------------------------------------------------------
// UART Environment
// Top-level UVM environment containing all components
//-----------------------------------------------------------------------------

class uart_env extends uvm_env;
    `uvm_component_utils(uart_env)
    
    // Components
    uart_agent      agent;
    uart_scoreboard scoreboard;
    uart_coverage   coverage;
    
    function new(string name = "uart_env", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create agent
        agent = uart_agent::type_id::create("agent", this);
        
        // Create scoreboard
        scoreboard = uart_scoreboard::type_id::create("scoreboard", this);
        
        // Create coverage collector
        coverage = uart_coverage::type_id::create("coverage", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect agent to scoreboard
        agent.tx_ap.connect(scoreboard.tx_fifo.analysis_export);
        agent.rx_ap.connect(scoreboard.rx_fifo.analysis_export);
        
        // Connect agent to coverage
        agent.tx_ap.connect(coverage.analysis_export);
    endfunction
    
endclass
