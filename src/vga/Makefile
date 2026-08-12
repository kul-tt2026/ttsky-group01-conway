# ---------- cocotb setup for VGA modules ----------

SIM           ?= icarus
TOPLEVEL_LANG ?= verilog

# List of DUTs that have cocotb tests
COCOTB_DUTS = vga_get_cell_idx vga_get_cell_type vga_get_pixel_color

# Require DUT for cocotb / cocotb_all, but NOT for clean
ifeq ($(strip $(DUT)),)
ifneq ($(MAKECMDGOALS),cocotb_all)
ifneq ($(MAKECMDGOALS),clean)
$(error You must specify DUT, e.g. 'make cocotb DUT=vga_get_cell_type')
endif
endif
endif

VERILOG_SOURCES     = $(PWD)/$(DUT).sv
TOPLEVEL            = $(DUT)
COCOTB_TEST_MODULES = test_$(DUT)
COCOTB_RESULTS_FILE ?= results_$(DUT).xml
SIM_BUILD            = sim_build_$(DUT)

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: cocotb
cocotb:
	$(MAKE) sim    # 'sim' from Makefile.sim runs cocotb

.PHONY: cocotb_all
cocotb_all:
	$(MAKE) clean
	@status=0; \
	for d in $(COCOTB_DUTS); do \
		$(MAKE) cocotb DUT=$$d COCOTB_RESULTS_FILE=results_$$d.xml || status=1; \
	done; \
	python3 merge_results.py results_*.xml -o results.xml; \
	exit $$status

.PHONY: clean
clean::
	rm -f results*.xml
	rm -rf sim_build sim_build_* __pycache__