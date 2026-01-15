SIM ?= verilator
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES = $(shell pwd)/*.sv
TOPLEVEL = day2
MODULE = tbench

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ns

EXTRA_ARGS += --sv --trace
EXTRA_ARGS += --sv -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC --trace

# changes in Makefile now rebuild sim_build folder
CUSTOM_COMPILE_DEPS = ./Makefile 

include $(shell cocotb-config --makefiles)/Makefile.sim