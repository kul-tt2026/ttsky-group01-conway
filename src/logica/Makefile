# Deel Sieben, logica
# Elegentere syntax van Claude Opus 5
# simuleer iets door bv. "make simulate L_sweeper" (in src/logica)
# verwijder temp output via "make clean" (in src/logica)

IVERILOG = iverilog
FLAGS    = -g2012

MODULES = L_rowcol_counter L_sweep_counter L_sweeper L_decider L_controller

simulate_%:
	$(IVERILOG) $(FLAGS) -o sim_$*.out $*.sv tb_$*.sv
	./sim_$*.out

.PHONY: simulate_all
simulate_all: $(addprefix simulate_,$(MODULES))

.PHONY: simulate_L_main
simulate_L_main:
	$(MAKE) -f Makefile.cocotb

.PHONY: clean
clean:
	rm -f sim*.out tb_L_*.vcd
	$(MAKE) -f Makefile.cocotb clean