# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# Defaults
SIM             ?= icarus
FST             ?= -fst # Use more efficient FST format
TOPLEVEL_LANG   ?= verilog
SRC_DIR          = $(PWD)/../src
VERILOG_INCLUDE_DIRS += $(SRC_DIR)
PROJECT_SOURCES  = project.sv vga/vga.sv vga/vga_hvsync_generator.sv register_board/register_board.sv logica/L_controller.sv logica/L_datapath.sv logica/L_decider.sv logica/L_main.sv logica/L_rowcol_counter.sv logica/L_sweep_counter.sv logica/L_sweeper.sv

ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD        = sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

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
VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL         = tb

# List test modules to run, separated by commas !NO SPACES! and without the .py suffix:
COCOTB_TEST_MODULES = test_vga,test_vga_comprehensive

# Include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

# Extend cocotb's clean target to also remove build artifacts
.PHONY: clean
clean::
	rm -rf sim_build/ __pycache__/ results.xml tb.fst tb.gtkw
