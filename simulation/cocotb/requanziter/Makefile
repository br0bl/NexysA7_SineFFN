SIM = icarus
TOPLEVEL_LANG = verilog 
VERILOG_SOURCES = $(PWD)/../../../sources/requantizer.v $(PWD)/../../../sources/multiplier_32b.v 
COCOTB_TOPLEVEL = requantizer
COCOTB_TEST_MODULES = requantizer_cocotb
WAVES = 1
include $(shell cocotb-config --makefiles)/Makefile.sim
