# UART Controller Verification Project

## Project Overview
This project demonstrates a complete UVM-based verification environment for a simple UART (Universal Asynchronous Receiver/Transmitter) controller. The goal is to achieve high functional coverage and detect injected RTL bugs.

## Project Structure
```
UART_Veri/
├── rtl/                    # RTL design files
│   ├── uart_tx.sv          # UART Transmitter
│   ├── uart_rx.sv          # UART Receiver
│   ├── uart_top.sv         # Top-level UART module
│   └── uart_top_buggy.sv   # Buggy version for testing
├── tb/                     # UVM Testbench
│   ├── uart_pkg.sv         # Package with all TB components
│   ├── uart_if.sv          # Interface definition
│   ├── uart_seq_item.sv    # Sequence item
│   ├── uart_sequence.sv    # Sequences
│   ├── uart_driver.sv      # Driver
│   ├── uart_monitor.sv     # Monitor
│   ├── uart_agent.sv       # Agent
│   ├── uart_scoreboard.sv  # Scoreboard
│   ├── uart_coverage.sv    # Functional coverage
│   ├── uart_env.sv         # Environment
│   ├── uart_test.sv        # Test cases
│   └── uart_tb_top.sv      # Testbench top module
├── sim/                    # Simulation scripts
│   ├── Makefile            # Build and run scripts
│   └── run.do              # QuestaSim/ModelSim script
├── docs/                   # Documentation
│   ├── verification_plan.md
│   ├── coverage_report.md
│   └── bugs_found.md
└── README.md
```

## UART Specifications
- **Data Width**: 8 bits
- **Baud Rates**: Configurable (9600, 19200, 38400, 57600, 115200)
- **Parity**: None, Even, Odd
- **Stop Bits**: 1 or 2
- **Flow Control**: None (simplified design)

## Verification Goals
1. **Functional Coverage**: Target 95%+
2. **Code Coverage**: Target 90%+
3. **Bug Detection**: Catch all 4 injected bugs

## Injected Bugs (for demonstration)
1. Off-by-one error in baud rate counter
2. Wrong parity calculation (XOR vs XNOR)
3. Missing stop bit check in receiver
4. Incorrect data bit sampling point

## How to Run
```bash
cd sim/
make compile    # Compile all files
make sim        # Run simulation
make coverage   # Generate coverage report
make clean      # Clean generated files
```

## Tools Required
- SystemVerilog simulator (QuestaSim, VCS, Xcelium, or Verilator)
- UVM 1.2 library

## Author
Tushar Dhananjay Pathak

## License
MIT License
