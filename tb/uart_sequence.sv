//-----------------------------------------------------------------------------
// UART Sequences
// Various test sequences for UART verification
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Base Sequence
//-----------------------------------------------------------------------------
class uart_base_sequence extends uvm_sequence #(uart_seq_item);
    `uvm_object_utils(uart_base_sequence)
    
    function new(string name = "uart_base_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        // Override in derived classes
    endtask
endclass

//-----------------------------------------------------------------------------
// Single Transfer Sequence
//-----------------------------------------------------------------------------
class uart_single_sequence extends uart_base_sequence;
    `uvm_object_utils(uart_single_sequence)
    
    // Configurable parameters
    logic [7:0]  data_to_send = 8'hA5;
    logic [31:0] baud = 115200;
    logic [1:0]  parity = 0;
    logic        stop = 0;
    
    function new(string name = "uart_single_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        uart_seq_item item;
        
        item = uart_seq_item::type_id::create("item");
        start_item(item);
        
        if (!item.randomize() with {
            tx_data == local::data_to_send;
            baud_rate == local::baud;
            parity_mode == local::parity;
            stop_bits == local::stop;
            delay_cycles == 0;
        }) begin
            `uvm_error(get_type_name(), "Randomization failed")
        end
        
        finish_item(item);
        `uvm_info(get_type_name(), $sformatf("Sent: %s", item.convert2string()), UVM_MEDIUM)
    endtask
endclass

//-----------------------------------------------------------------------------
// Burst Transfer Sequence
//-----------------------------------------------------------------------------
class uart_burst_sequence extends uart_base_sequence;
    `uvm_object_utils(uart_burst_sequence)
    
    rand int unsigned num_transfers;
    logic [31:0] baud = 115200;
    logic [1:0]  parity = 0;
    logic        stop = 0;
    
    constraint c_num_transfers {
        num_transfers inside {[4:16]};
    }
    
    function new(string name = "uart_burst_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        uart_seq_item item;
        
        `uvm_info(get_type_name(), $sformatf("Starting burst of %0d transfers", num_transfers), UVM_MEDIUM)
        
        for (int i = 0; i < num_transfers; i++) begin
            item = uart_seq_item::type_id::create($sformatf("item_%0d", i));
            start_item(item);
            
            if (!item.randomize() with {
                baud_rate == local::baud;
                parity_mode == local::parity;
                stop_bits == local::stop;
                delay_cycles inside {[0:10]};
            }) begin
                `uvm_error(get_type_name(), "Randomization failed")
            end
            
            finish_item(item);
            `uvm_info(get_type_name(), $sformatf("Burst[%0d]: %s", i, item.convert2string()), UVM_HIGH)
        end
    endtask
endclass

//-----------------------------------------------------------------------------
// Random Configuration Sequence
//-----------------------------------------------------------------------------
class uart_random_sequence extends uart_base_sequence;
    `uvm_object_utils(uart_random_sequence)
    
    rand int unsigned num_transfers;
    
    constraint c_num_transfers {
        num_transfers inside {[10:50]};
    }
    
    function new(string name = "uart_random_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        uart_seq_item item;
        
        `uvm_info(get_type_name(), $sformatf("Starting random sequence with %0d transfers", num_transfers), UVM_MEDIUM)
        
        for (int i = 0; i < num_transfers; i++) begin
            item = uart_seq_item::type_id::create($sformatf("item_%0d", i));
            start_item(item);
            
            if (!item.randomize()) begin
                `uvm_error(get_type_name(), "Randomization failed")
            end
            
            finish_item(item);
            `uvm_info(get_type_name(), $sformatf("Random[%0d]: %s", i, item.convert2string()), UVM_HIGH)
        end
    endtask
endclass

//-----------------------------------------------------------------------------
// All Baud Rates Sequence
//-----------------------------------------------------------------------------
class uart_all_baud_sequence extends uart_base_sequence;
    `uvm_object_utils(uart_all_baud_sequence)
    
    function new(string name = "uart_all_baud_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        uart_seq_item item;
        int baud_rates[] = '{9600, 19200, 38400, 57600, 115200};
        
        `uvm_info(get_type_name(), "Testing all baud rates", UVM_MEDIUM)
        
        foreach (baud_rates[i]) begin
            item = uart_seq_item::type_id::create($sformatf("item_baud_%0d", baud_rates[i]));
            start_item(item);
            
            if (!item.randomize() with {
                baud_rate == baud_rates[i];
                parity_mode == 0;
                stop_bits == 0;
            }) begin
                `uvm_error(get_type_name(), "Randomization failed")
            end
            
            finish_item(item);
            `uvm_info(get_type_name(), $sformatf("Baud %0d: %s", baud_rates[i], item.convert2string()), UVM_MEDIUM)
        end
    endtask
endclass

//-----------------------------------------------------------------------------
// Parity Test Sequence
//-----------------------------------------------------------------------------
class uart_parity_sequence extends uart_base_sequence;
    `uvm_object_utils(uart_parity_sequence)
    
    logic [1:0] parity_type = 1;  // 1=Even, 2=Odd
    
    function new(string name = "uart_parity_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        uart_seq_item item;
        
        `uvm_info(get_type_name(), $sformatf("Testing parity mode %0d", parity_type), UVM_MEDIUM)
        
        // Test with various data patterns
        logic [7:0] test_data[] = '{8'h00, 8'hFF, 8'h55, 8'hAA, 8'h0F, 8'hF0};
        
        foreach (test_data[i]) begin
            item = uart_seq_item::type_id::create($sformatf("item_%0d", i));
            start_item(item);
            
            if (!item.randomize() with {
                tx_data == test_data[i];
                baud_rate == 115200;
                parity_mode == local::parity_type;
                stop_bits == 0;
            }) begin
                `uvm_error(get_type_name(), "Randomization failed")
            end
            
            finish_item(item);
            `uvm_info(get_type_name(), $sformatf("Parity test: %s", item.convert2string()), UVM_MEDIUM)
        end
    endtask
endclass

//-----------------------------------------------------------------------------
// Corner Case Sequence
//-----------------------------------------------------------------------------
class uart_corner_sequence extends uart_base_sequence;
    `uvm_object_utils(uart_corner_sequence)
    
    function new(string name = "uart_corner_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        uart_seq_item item;
        
        `uvm_info(get_type_name(), "Testing corner cases", UVM_MEDIUM)
        
        // All zeros
        item = uart_seq_item::type_id::create("item_zeros");
        start_item(item);
        assert(item.randomize() with { tx_data == 8'h00; baud_rate == 115200; });
        finish_item(item);
        
        // All ones
        item = uart_seq_item::type_id::create("item_ones");
        start_item(item);
        assert(item.randomize() with { tx_data == 8'hFF; baud_rate == 115200; });
        finish_item(item);
        
        // Alternating patterns
        item = uart_seq_item::type_id::create("item_alt1");
        start_item(item);
        assert(item.randomize() with { tx_data == 8'h55; baud_rate == 115200; });
        finish_item(item);
        
        item = uart_seq_item::type_id::create("item_alt2");
        start_item(item);
        assert(item.randomize() with { tx_data == 8'hAA; baud_rate == 115200; });
        finish_item(item);
        
        // Single bit patterns
        for (int i = 0; i < 8; i++) begin
            item = uart_seq_item::type_id::create($sformatf("item_bit%0d", i));
            start_item(item);
            assert(item.randomize() with { tx_data == (1 << i); baud_rate == 115200; });
            finish_item(item);
        end
    endtask
endclass
