#------------------------------------------------------------------------------
# QuestaSim/ModelSim DO file for UART Verification
#------------------------------------------------------------------------------

# Set working directory
cd ../sim

# Create work library
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Set UVM home (adjust path as needed)
set UVM_HOME $env(QUESTA_HOME)/verilog_src/uvm-1.2

# Compile UVM
vlog -sv +incdir+$UVM_HOME/src $UVM_HOME/src/uvm_pkg.sv

# Compile RTL
vlog -sv ../rtl/uart_tx.sv
vlog -sv ../rtl/uart_rx.sv
vlog -sv ../rtl/uart_top.sv

# Compile Testbench
vlog -sv +incdir+../tb ../tb/uart_if.sv
vlog -sv +incdir+../tb ../tb/uart_pkg.sv
vlog -sv +incdir+../tb ../tb/uart_tb_top.sv

# Set test name (can be overridden from command line)
if {![info exists TEST]} {
    set TEST "uart_loopback_test"
}

# Run simulation
vsim -c -sv_seed random \
     +UVM_TESTNAME=$TEST \
     +UVM_VERBOSITY=UVM_MEDIUM \
     -coverage \
     work.uart_tb_top

# Add waves
add wave -position insertpoint sim:/uart_tb_top/*
add wave -position insertpoint sim:/uart_tb_top/dut/*
add wave -position insertpoint sim:/uart_tb_top/dut/u_uart_tx/*
add wave -position insertpoint sim:/uart_tb_top/dut/u_uart_rx/*

# Run
run -all

# Generate coverage report
# coverage report -html -output coverage_html

# Quit
quit
