# HOW TO TEST VGA:
# make cocotb

# quick test only .sv files:
# make simulate_all
# make simulate_filename
# make sv

# ---------- Snelle Icarus simulatie van pure SV-testbenches ----------
IVERILOG = iverilog
FLAGS    = -g2012

MODULES  = vga_get_cell_idx

.PHONY: simulate_% simulate_all sv
simulate_%:
	$(IVERILOG) $(FLAGS) -o sim_$*.out $*.sv tb_$*.sv
	./sim_$*.out

simulate_all: $(addprefix simulate_,$(MODULES))

# Laat 'sv' het standaard SV-doel zijn
sv: simulate_vga_get_cell_idx


# ---------- cocotb-set-up voor Python tests + results.xml ----------
SIM             ?= icarus
TOPLEVEL_LANG   ?= verilog

VERILOG_SOURCES += $(PWD)/vga_get_cell_idx.sv

TOPLEVEL         = vga_get_cell_idx
COCOTB_TEST_MODULES = test_vga_get_cell_idx
COCOTB_RESULTS_FILE ?= results.xml

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: cocotb
cocotb:
	$(MAKE) sim    # 'sim' target komt uit Makefile.sim en runt cocotb

.PHONY: clean
clean::
	rm -f sim_*.out tb_*.vcd *.fst results.xml
	rm -rf sim_build/ __pycache__