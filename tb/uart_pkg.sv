//-----------------------------------------------------------------------------
// UART Package
// Contains all UVM testbench components
//-----------------------------------------------------------------------------

package uart_pkg;
    
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    // Include testbench components
    `include "uart_seq_item.sv"
    `include "uart_sequence.sv"
    `include "uart_driver.sv"
    `include "uart_monitor.sv"
    `include "uart_agent.sv"
    `include "uart_scoreboard.sv"
    `include "uart_coverage.sv"
    `include "uart_env.sv"
    `include "uart_test.sv"
    
endpackage
