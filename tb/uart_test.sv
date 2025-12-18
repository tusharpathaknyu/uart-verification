//-----------------------------------------------------------------------------
// UART Test Cases
// Various test scenarios for UART verification
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Base Test
//-----------------------------------------------------------------------------
class uart_base_test extends uvm_test;
    `uvm_component_utils(uart_base_test)
    
    uart_env env;
    virtual uart_if vif;
    
    function new(string name = "uart_base_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create environment
        env = uart_env::type_id::create("env", this);
        
        // Get virtual interface
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "Virtual interface not found")
        end
    endfunction
    
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        // Print topology
        uvm_top.print_topology();
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "Starting test...", UVM_LOW)
        
        // Reset sequence
        apply_reset();
        
        // Run test-specific sequence
        run_test_sequence();
        
        // Drain time
        #1000;
        
        `uvm_info(get_type_name(), "Test complete.", UVM_LOW)
        
        phase.drop_objection(this);
    endtask
    
    virtual task apply_reset();
        `uvm_info(get_type_name(), "Applying reset...", UVM_MEDIUM)
        // Reset is handled in tb_top
        repeat(10) @(posedge vif.clk);
    endtask
    
    virtual task run_test_sequence();
        // Override in derived tests
    endtask
    
endclass

//-----------------------------------------------------------------------------
// Basic TX Test
//-----------------------------------------------------------------------------
class uart_basic_tx_test extends uart_base_test;
    `uvm_component_utils(uart_basic_tx_test)
    
    function new(string name = "uart_basic_tx_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_test_sequence();
        uart_single_sequence seq;
        
        `uvm_info(get_type_name(), "Running basic TX test", UVM_LOW)
        
        seq = uart_single_sequence::type_id::create("seq");
        seq.data_to_send = 8'hA5;
        seq.baud = 115200;
        seq.parity = 0;
        seq.stop = 0;
        
        seq.start(env.agent.sequencer);
    endtask
endclass

//-----------------------------------------------------------------------------
// Loopback Test
//-----------------------------------------------------------------------------
class uart_loopback_test extends uart_base_test;
    `uvm_component_utils(uart_loopback_test)
    
    function new(string name = "uart_loopback_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_test_sequence();
        uart_burst_sequence seq;
        
        `uvm_info(get_type_name(), "Running loopback test", UVM_LOW)
        
        seq = uart_burst_sequence::type_id::create("seq");
        seq.num_transfers = 10;
        seq.baud = 115200;
        seq.parity = 0;
        seq.stop = 0;
        
        seq.start(env.agent.sequencer);
    endtask
endclass

//-----------------------------------------------------------------------------
// All Baud Rates Test
//-----------------------------------------------------------------------------
class uart_all_baud_test extends uart_base_test;
    `uvm_component_utils(uart_all_baud_test)
    
    function new(string name = "uart_all_baud_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_test_sequence();
        uart_all_baud_sequence seq;
        
        `uvm_info(get_type_name(), "Running all baud rates test", UVM_LOW)
        
        seq = uart_all_baud_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
    endtask
endclass

//-----------------------------------------------------------------------------
// Even Parity Test
//-----------------------------------------------------------------------------
class uart_parity_even_test extends uart_base_test;
    `uvm_component_utils(uart_parity_even_test)
    
    function new(string name = "uart_parity_even_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_test_sequence();
        uart_parity_sequence seq;
        
        `uvm_info(get_type_name(), "Running even parity test", UVM_LOW)
        
        seq = uart_parity_sequence::type_id::create("seq");
        seq.parity_type = 1;  // Even parity
        seq.start(env.agent.sequencer);
    endtask
endclass

//-----------------------------------------------------------------------------
// Odd Parity Test
//-----------------------------------------------------------------------------
class uart_parity_odd_test extends uart_base_test;
    `uvm_component_utils(uart_parity_odd_test)
    
    function new(string name = "uart_parity_odd_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_test_sequence();
        uart_parity_sequence seq;
        
        `uvm_info(get_type_name(), "Running odd parity test", UVM_LOW)
        
        seq = uart_parity_sequence::type_id::create("seq");
        seq.parity_type = 2;  // Odd parity
        seq.start(env.agent.sequencer);
    endtask
endclass

//-----------------------------------------------------------------------------
// Two Stop Bits Test
//-----------------------------------------------------------------------------
class uart_two_stop_test extends uart_base_test;
    `uvm_component_utils(uart_two_stop_test)
    
    function new(string name = "uart_two_stop_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_test_sequence();
        uart_burst_sequence seq;
        
        `uvm_info(get_type_name(), "Running two stop bits test", UVM_LOW)
        
        seq = uart_burst_sequence::type_id::create("seq");
        seq.num_transfers = 5;
        seq.baud = 115200;
        seq.parity = 0;
        seq.stop = 1;  // Two stop bits
        
        seq.start(env.agent.sequencer);
    endtask
endclass

//-----------------------------------------------------------------------------
// Corner Cases Test
//-----------------------------------------------------------------------------
class uart_corner_test extends uart_base_test;
    `uvm_component_utils(uart_corner_test)
    
    function new(string name = "uart_corner_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_test_sequence();
        uart_corner_sequence seq;
        
        `uvm_info(get_type_name(), "Running corner cases test", UVM_LOW)
        
        seq = uart_corner_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
    endtask
endclass

//-----------------------------------------------------------------------------
// Random Test
//-----------------------------------------------------------------------------
class uart_random_test extends uart_base_test;
    `uvm_component_utils(uart_random_test)
    
    function new(string name = "uart_random_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_test_sequence();
        uart_random_sequence seq;
        
        `uvm_info(get_type_name(), "Running random test", UVM_LOW)
        
        seq = uart_random_sequence::type_id::create("seq");
        seq.num_transfers = 50;
        seq.start(env.agent.sequencer);
    endtask
endclass

//-----------------------------------------------------------------------------
// Stress Test (Extended Random)
//-----------------------------------------------------------------------------
class uart_stress_test extends uart_base_test;
    `uvm_component_utils(uart_stress_test)
    
    function new(string name = "uart_stress_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_test_sequence();
        uart_random_sequence seq;
        
        `uvm_info(get_type_name(), "Running stress test", UVM_LOW)
        
        seq = uart_random_sequence::type_id::create("seq");
        seq.num_transfers = 200;
        seq.start(env.agent.sequencer);
    endtask
endclass

//-----------------------------------------------------------------------------
// Full Coverage Test
// Runs multiple sequences to achieve high coverage
//-----------------------------------------------------------------------------
class uart_full_coverage_test extends uart_base_test;
    `uvm_component_utils(uart_full_coverage_test)
    
    function new(string name = "uart_full_coverage_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_test_sequence();
        uart_all_baud_sequence baud_seq;
        uart_parity_sequence even_seq, odd_seq;
        uart_corner_sequence corner_seq;
        uart_random_sequence random_seq;
        uart_burst_sequence burst_seq;
        
        `uvm_info(get_type_name(), "Running full coverage test", UVM_LOW)
        
        // Test all baud rates
        baud_seq = uart_all_baud_sequence::type_id::create("baud_seq");
        baud_seq.start(env.agent.sequencer);
        
        // Test even parity
        even_seq = uart_parity_sequence::type_id::create("even_seq");
        even_seq.parity_type = 1;
        even_seq.start(env.agent.sequencer);
        
        // Test odd parity
        odd_seq = uart_parity_sequence::type_id::create("odd_seq");
        odd_seq.parity_type = 2;
        odd_seq.start(env.agent.sequencer);
        
        // Test corner cases
        corner_seq = uart_corner_sequence::type_id::create("corner_seq");
        corner_seq.start(env.agent.sequencer);
        
        // Test two stop bits at various bauds
        burst_seq = uart_burst_sequence::type_id::create("burst_seq");
        burst_seq.stop = 1;
        burst_seq.start(env.agent.sequencer);
        
        // Random testing
        random_seq = uart_random_sequence::type_id::create("random_seq");
        random_seq.num_transfers = 100;
        random_seq.start(env.agent.sequencer);
        
        `uvm_info(get_type_name(), "Full coverage test complete", UVM_LOW)
    endtask
endclass
