SIM = icarus
TOPLEVEL_LANG = verilog 

VERILOG_SOURCES = \
	$(PWD)/../sources/ffn_core.v \
	$(PWD)/../sources/mac.v \
	$(PWD)/../sources/multiplier_32b.v \
	$(PWD)/../sources/param_rom.v \
	$(PWD)/../sources/parameters.v \
	$(PWD)/../sources/requantizer.v 

COCOTB_TOPLEVEL = ffn_core
COCOTB_TEST_MODULES = ffn_cocotb
WAVES = 1
include $(shell cocotb-config --makefiles)/Makefile.sim
