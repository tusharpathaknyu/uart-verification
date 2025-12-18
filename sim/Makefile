#------------------------------------------------------------------------------
# UART Verification Makefile
# Supports QuestaSim/ModelSim, VCS, and Verilator
#------------------------------------------------------------------------------

# Default simulator
SIM ?= questa

# Directories
RTL_DIR    = ../rtl
TB_DIR     = ../tb
WORK_DIR   = work
LOG_DIR    = logs
COV_DIR    = coverage

# Source files
RTL_FILES  = $(RTL_DIR)/uart_tx.sv \
             $(RTL_DIR)/uart_rx.sv \
             $(RTL_DIR)/uart_top.sv

RTL_BUGGY  = $(RTL_DIR)/uart_tx_buggy.sv \
             $(RTL_DIR)/uart_rx_buggy.sv \
             $(RTL_DIR)/uart_top_buggy.sv

TB_FILES   = $(TB_DIR)/uart_if.sv \
             $(TB_DIR)/uart_pkg.sv \
             $(TB_DIR)/uart_tb_top.sv

# UVM home (adjust for your installation)
UVM_HOME   ?= $(QUESTA_HOME)/verilog_src/uvm-1.2

# Default test
TEST ?= uart_loopback_test

# Seed for randomization
SEED ?= random

#------------------------------------------------------------------------------
# QuestaSim/ModelSim targets
#------------------------------------------------------------------------------
ifeq ($(SIM),questa)

VLOG = vlog
VSIM = vsim
VLIB = vlib
VCOVER = vcover

VLOG_OPTS = -sv +incdir+$(TB_DIR) +incdir+$(UVM_HOME)/src \
            -work $(WORK_DIR) \
            +define+UVM_NO_DEPRECATED \
            -suppress 2583

VSIM_OPTS = -c -do "run -all; quit" \
            -sv_seed $(SEED) \
            +UVM_TESTNAME=$(TEST) \
            +UVM_VERBOSITY=UVM_MEDIUM \
            -coverage \
            -work $(WORK_DIR)

compile: clean_work
	@mkdir -p $(WORK_DIR) $(LOG_DIR)
	$(VLIB) $(WORK_DIR)
	$(VLOG) $(VLOG_OPTS) $(UVM_HOME)/src/uvm_pkg.sv
	$(VLOG) $(VLOG_OPTS) $(RTL_FILES) $(TB_FILES) 2>&1 | tee $(LOG_DIR)/compile.log

compile_buggy: clean_work
	@mkdir -p $(WORK_DIR) $(LOG_DIR)
	$(VLIB) $(WORK_DIR)
	$(VLOG) $(VLOG_OPTS) $(UVM_HOME)/src/uvm_pkg.sv
	$(VLOG) $(VLOG_OPTS) $(RTL_BUGGY) $(TB_FILES) 2>&1 | tee $(LOG_DIR)/compile.log

sim: compile
	@mkdir -p $(LOG_DIR)
	$(VSIM) $(VSIM_OPTS) uart_tb_top 2>&1 | tee $(LOG_DIR)/sim_$(TEST).log

sim_buggy: compile_buggy
	@mkdir -p $(LOG_DIR)
	$(VSIM) $(VSIM_OPTS) uart_tb_top 2>&1 | tee $(LOG_DIR)/sim_buggy_$(TEST).log

gui: compile
	$(VSIM) -gui $(VSIM_OPTS:-c=) uart_tb_top

coverage:
	@mkdir -p $(COV_DIR)
	$(VCOVER) report -html -output $(COV_DIR)/html $(WORK_DIR)
	@echo "Coverage report generated in $(COV_DIR)/html"

endif

#------------------------------------------------------------------------------
# VCS targets
#------------------------------------------------------------------------------
ifeq ($(SIM),vcs)

VCS = vcs
SIMV = ./simv

VCS_OPTS = -full64 -sverilog \
           +incdir+$(TB_DIR) \
           -timescale=1ns/1ps \
           -ntb_opts uvm-1.2 \
           -debug_access+all \
           -cm line+cond+fsm+tgl+branch

SIMV_OPTS = +UVM_TESTNAME=$(TEST) \
            +UVM_VERBOSITY=UVM_MEDIUM \
            +ntb_random_seed=$(SEED) \
            -cm line+cond+fsm+tgl+branch

compile: clean_work
	@mkdir -p $(LOG_DIR)
	$(VCS) $(VCS_OPTS) $(RTL_FILES) $(TB_FILES) -o $(SIMV) 2>&1 | tee $(LOG_DIR)/compile.log

compile_buggy: clean_work
	@mkdir -p $(LOG_DIR)
	$(VCS) $(VCS_OPTS) $(RTL_BUGGY) $(TB_FILES) -o $(SIMV) 2>&1 | tee $(LOG_DIR)/compile.log

sim: compile
	@mkdir -p $(LOG_DIR)
	$(SIMV) $(SIMV_OPTS) 2>&1 | tee $(LOG_DIR)/sim_$(TEST).log

sim_buggy: compile_buggy
	@mkdir -p $(LOG_DIR)
	$(SIMV) $(SIMV_OPTS) 2>&1 | tee $(LOG_DIR)/sim_buggy_$(TEST).log

coverage:
	@mkdir -p $(COV_DIR)
	urg -dir simv.vdb -report $(COV_DIR)
	@echo "Coverage report generated in $(COV_DIR)"

endif

#------------------------------------------------------------------------------
# Verilator targets (limited UVM support)
#------------------------------------------------------------------------------
ifeq ($(SIM),verilator)

VERILATOR = verilator

compile:
	@echo "Verilator has limited UVM support. Use questa or vcs for full UVM."
	@echo "For basic RTL simulation without UVM:"
	$(VERILATOR) --cc --exe --build \
	    -Wall --trace \
	    $(RTL_FILES)

endif

#------------------------------------------------------------------------------
# Common targets
#------------------------------------------------------------------------------

# Run all tests
regress: compile
	@mkdir -p $(LOG_DIR)
	@for test in uart_basic_tx_test uart_loopback_test uart_all_baud_test \
	             uart_parity_even_test uart_parity_odd_test uart_two_stop_test \
	             uart_corner_test uart_random_test; do \
	    echo "Running $$test..."; \
	    $(MAKE) sim TEST=$$test; \
	done

# Run regression on buggy RTL
regress_buggy: compile_buggy
	@mkdir -p $(LOG_DIR)
	@for test in uart_basic_tx_test uart_loopback_test uart_all_baud_test \
	             uart_parity_even_test uart_parity_odd_test uart_random_test; do \
	    echo "Running $$test on buggy RTL..."; \
	    $(MAKE) sim_buggy TEST=$$test; \
	done

# Clean work directory
clean_work:
	rm -rf $(WORK_DIR)
	rm -f transcript vsim.wlf

# Clean all generated files
clean: clean_work
	rm -rf $(LOG_DIR) $(COV_DIR)
	rm -f *.vcd simv simv.daidir
	rm -rf csrc DVEfiles urgReport

# View waveforms
waves:
	gtkwave uart_tb.vcd &

# Help
help:
	@echo "UART Verification Makefile"
	@echo ""
	@echo "Usage: make <target> [SIM=questa|vcs|verilator] [TEST=<test_name>] [SEED=<seed>]"
	@echo ""
	@echo "Targets:"
	@echo "  compile      - Compile RTL and testbench"
	@echo "  compile_buggy- Compile buggy RTL and testbench"
	@echo "  sim          - Run simulation with TEST"
	@echo "  sim_buggy    - Run simulation with buggy RTL"
	@echo "  gui          - Run simulation with GUI"
	@echo "  regress      - Run all tests"
	@echo "  regress_buggy- Run all tests on buggy RTL"
	@echo "  coverage     - Generate coverage report"
	@echo "  clean        - Clean all generated files"
	@echo "  waves        - Open waveform viewer"
	@echo ""
	@echo "Available tests:"
	@echo "  uart_basic_tx_test"
	@echo "  uart_loopback_test"
	@echo "  uart_all_baud_test"
	@echo "  uart_parity_even_test"
	@echo "  uart_parity_odd_test"
	@echo "  uart_two_stop_test"
	@echo "  uart_corner_test"
	@echo "  uart_random_test"
	@echo "  uart_stress_test"
	@echo "  uart_full_coverage_test"

.PHONY: compile compile_buggy sim sim_buggy gui regress regress_buggy \
        coverage clean clean_work waves help
