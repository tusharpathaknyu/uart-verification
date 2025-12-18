# UART Verification Plan

## 1. Introduction

### 1.1 Purpose
This document describes the verification plan for the UART (Universal Asynchronous Receiver/Transmitter) controller. The goal is to achieve comprehensive verification using UVM methodology.

### 1.2 Scope
- UART Transmitter (TX)
- UART Receiver (RX)  
- Loopback functionality
- Error detection

### 1.3 References
- UART Protocol Specification
- UVM 1.2 Reference Manual

---

## 2. DUT Features

### 2.1 Configurable Parameters
| Parameter | Values | Description |
|-----------|--------|-------------|
| Baud Rate | 9600, 19200, 38400, 57600, 115200 | Transmission speed |
| Parity | None, Even, Odd | Error detection |
| Stop Bits | 1, 2 | End of frame |
| Data Width | 8 bits | Fixed |

### 2.2 Interfaces
- **TX Data Interface**: tx_data[7:0], tx_valid, tx_ready, tx_done
- **RX Data Interface**: rx_data[7:0], rx_valid, rx_error
- **Serial Interface**: uart_tx, uart_rx
- **Configuration**: baud_rate, parity_mode, stop_bits

---

## 3. Verification Features

### 3.1 Features to be Verified
| ID | Feature | Priority | Description |
|----|---------|----------|-------------|
| F1 | TX Basic Operation | High | Transmit data correctly |
| F2 | RX Basic Operation | High | Receive data correctly |
| F3 | Baud Rate Accuracy | High | Timing within ±2% |
| F4 | Parity Generation (TX) | High | Correct parity bit |
| F5 | Parity Checking (RX) | High | Detect parity errors |
| F6 | Framing Error Detection | Medium | Detect missing stop bits |
| F7 | Multiple Stop Bits | Medium | 1 and 2 stop bits |
| F8 | Back-to-back Transfers | Medium | Continuous operation |
| F9 | Loopback | High | TX to RX data integrity |

### 3.2 Features Not Verified (Out of Scope)
- Hardware flow control (RTS/CTS)
- Multi-drop configurations
- Break detection

---

## 4. Verification Architecture

### 4.1 UVM Testbench Components

```
┌─────────────────────────────────────────────────────────────┐
│                         TEST                                │
├─────────────────────────────────────────────────────────────┤
│                       ENVIRONMENT                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   TX AGENT      │  │   RX AGENT      │  │ SCOREBOARD  │ │
│  │  ┌───────────┐  │  │  ┌───────────┐  │  │             │ │
│  │  │ Sequencer │  │  │  │  Monitor  │  │  │  Reference  │ │
│  │  ├───────────┤  │  │  └───────────┘  │  │    Model    │ │
│  │  │  Driver   │  │  │                 │  │             │ │
│  │  ├───────────┤  │  │                 │  │  Comparator │ │
│  │  │  Monitor  │  │  │                 │  │             │ │
│  │  └───────────┘  │  │                 │  └─────────────┘ │
│  └─────────────────┘  └─────────────────┘                  │
│                                           ┌─────────────┐   │
│                                           │  COVERAGE   │   │
│                                           └─────────────┘   │
└─────────────────────────────────────────────────────────────┘
                           │
                    ┌──────┴──────┐
                    │  INTERFACE  │
                    └──────┬──────┘
                           │
                    ┌──────┴──────┐
                    │     DUT     │
                    └─────────────┘
```

### 4.2 Components Description

| Component | Purpose |
|-----------|---------|
| uart_seq_item | Transaction object for UART data |
| uart_driver | Drives TX data to DUT |
| uart_monitor | Monitors UART signals |
| uart_sequencer | Controls sequence flow |
| uart_agent | Groups driver, monitor, sequencer |
| uart_scoreboard | Compares expected vs actual |
| uart_coverage | Functional coverage collection |
| uart_env | Top-level environment |

---

## 5. Coverage Model

### 5.1 Functional Coverage

#### 5.1.1 Configuration Coverage
```systemverilog
covergroup cfg_cg;
    baud_cp: coverpoint baud_rate {
        bins b9600   = {9600};
        bins b19200  = {19200};
        bins b38400  = {38400};
        bins b57600  = {57600};
        bins b115200 = {115200};
    }
    
    parity_cp: coverpoint parity_mode {
        bins none = {0};
        bins even = {1};
        bins odd  = {2};
    }
    
    stop_cp: coverpoint stop_bits {
        bins one_bit  = {0};
        bins two_bits = {1};
    }
    
    // Cross coverage
    baud_x_parity: cross baud_cp, parity_cp;
    baud_x_stop: cross baud_cp, stop_cp;
endgroup
```

#### 5.1.2 Data Coverage
```systemverilog
covergroup data_cg;
    tx_data_cp: coverpoint tx_data {
        bins zero     = {8'h00};
        bins all_ones = {8'hFF};
        bins low      = {[8'h01:8'h3F]};
        bins mid      = {[8'h40:8'hBF]};
        bins high     = {[8'hC0:8'hFE]};
    }
    
    // Corner cases
    tx_pattern_cp: coverpoint tx_data {
        bins alternating_01 = {8'h55};
        bins alternating_10 = {8'hAA};
    }
endgroup
```

#### 5.1.3 Error Coverage
```systemverilog
covergroup error_cg;
    parity_err_cp: coverpoint parity_error {
        bins no_error = {0};
        bins error    = {1};
    }
    
    framing_err_cp: coverpoint framing_error {
        bins no_error = {0};
        bins error    = {1};
    }
endgroup
```

### 5.2 Coverage Goals
| Coverage Type | Target |
|--------------|--------|
| Functional Coverage | ≥95% |
| Code Coverage (Line) | ≥90% |
| Code Coverage (Branch) | ≥85% |
| Code Coverage (Toggle) | ≥80% |

---

## 6. Test Plan

### 6.1 Test Cases

| Test ID | Test Name | Description | Feature |
|---------|-----------|-------------|---------|
| TC001 | basic_tx_test | Single byte transmission | F1 |
| TC002 | basic_rx_test | Single byte reception | F2 |
| TC003 | loopback_test | TX to RX loopback | F9 |
| TC004 | all_baud_test | Test all baud rates | F3 |
| TC005 | parity_even_test | Even parity operation | F4, F5 |
| TC006 | parity_odd_test | Odd parity operation | F4, F5 |
| TC007 | parity_error_test | Inject parity errors | F5 |
| TC008 | framing_error_test | Missing stop bit | F6 |
| TC009 | two_stop_bits_test | 2 stop bits mode | F7 |
| TC010 | burst_test | Back-to-back transfers | F8 |
| TC011 | random_test | Randomized stimulus | All |
| TC012 | stress_test | Extended random testing | All |

### 6.2 Test Sequences

```
uart_base_sequence          (Base sequence class)
    ├── uart_single_seq     (Single byte transfer)
    ├── uart_burst_seq      (Multiple consecutive bytes)
    ├── uart_random_seq     (Random data and config)
    └── uart_error_seq      (Error injection)
```

---

## 7. Injected Bugs (for Demonstration)

These bugs will be injected into a buggy version of the RTL to demonstrate testbench effectiveness.

| Bug ID | Description | Location | Expected Detection |
|--------|-------------|----------|-------------------|
| BUG001 | Off-by-one in baud counter | uart_tx.sv:52 | Timing analysis |
| BUG002 | Wrong parity (XOR vs XNOR) | uart_tx.sv:62 | Parity error test |
| BUG003 | Missing stop bit check | uart_rx.sv:145 | Framing error test |
| BUG004 | Wrong sampling point | uart_rx.sv:110 | Data mismatch |

---

## 8. Regression Strategy

### 8.1 Regression Levels
1. **Sanity** (~5 min): TC001, TC002, TC003
2. **Nightly** (~30 min): All directed tests
3. **Weekly** (~4 hrs): Directed + random with 1000 seeds

### 8.2 Pass/Fail Criteria
- All assertions pass
- No UVM_ERROR or UVM_FATAL
- Coverage targets met
- All bugs detected

---

## 9. Schedule

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| Testbench Development | 1 week | UVM environment |
| Directed Tests | 3 days | TC001-TC010 |
| Random Testing | 3 days | TC011-TC012 |
| Coverage Closure | 2 days | 95% coverage |
| Documentation | 1 day | Reports |

---

## 10. Sign-off Criteria

- [ ] All test cases passing
- [ ] Functional coverage ≥95%
- [ ] Code coverage ≥90%
- [ ] All 4 injected bugs detected
- [ ] No known issues
- [ ] Documentation complete
