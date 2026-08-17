# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# Defaults
SIM             ?= icarus
FST             ?= -fst # Use more efficient FST format

# Pass WAVES=yes to dump an FST waveform (tb.fst) of the run.
# Dumping slows the simulation down a lot, so it is off by default.
ifeq ($(WAVES),yes)
PLUSARGS += +WAVES
endif
TOPLEVEL_LANG   ?= verilog
SRC_DIR          = $(PWD)/../src
VERILOG_INCLUDE_DIRS += $(SRC_DIR)
VERILOG_INCLUDE_DIRS += $(SRC_DIR)/vga
VERILOG_INCLUDE_DIRS += $(SRC_DIR)/register_board
VERILOG_INCLUDE_DIRS += $(SRC_DIR)/logica
VERILOG_INCLUDE_DIRS += $(SRC_DIR)/Input

# RTL sources needed for the top-level Conway design.
# Order matters: sim_speed_pkg must come before anything that
# references sim_speed_pkg::speed_e (e.g. project_datapath.sv).
PROJECT_SOURCES := \
	$(SRC_DIR)/sim_speed.sv \
	$(SRC_DIR)/next_iter_countdown.sv \
	$(SRC_DIR)/project_controller.sv \
	$(SRC_DIR)/project_datapath.sv \
	$(wildcard $(SRC_DIR)/logica/L_*.sv) \
	$(filter-out %/tb_%,$(wildcard $(SRC_DIR)/register_board/*.sv)) \
	$(SRC_DIR)/vga/vga.sv \
	$(filter-out %/tb_%,$(wildcard $(SRC_DIR)/Input/*.sv)) \
	$(wildcard $(SRC_DIR)/vga/vga_*.sv) \
	$(SRC_DIR)/project.sv

ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD        = sim_build/rtl
VERILOG_SOURCES += $(PROJECT_SOURCES)

else

# Gate level simulation:
SIM_BUILD        = sim_build/gl
PDK_PATH        := $(shell find $(PDK_ROOT) -maxdepth 5 -type d -name $(PDK) 2>/dev/null | head -1)
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DUSE_POWER_PINS
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_PATH)/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_PATH)/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v

# This gets copied in by the GDS action workflow
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

# Include the testbench sources:
VERILOG_SOURCES += $(PWD)/tb.sv
TOPLEVEL         = tb

# List test modules to run, separated by commas !NO SPACES! and without the .py suffix:
COCOTB_TEST_MODULES = test

# Include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

# Extend cocotb's clean target to also remove build artifacts
.PHONY: clean
clean::
	rm -rf sim_build/ __pycache__/ results.xml tb.fst tb.gtkw output/
