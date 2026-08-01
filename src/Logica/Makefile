# Deel Sieben, logica

IVERILOG = iverilog
FLAGS    = -g2012

simulate_L_rowcol_counter:
	$(IVERILOG) $(FLAGS) -o sim.out L_rowcol_counter.sv tb_L_rowcol_counter.sv
	./sim.out

clean:
	rm -f sim.out tb_L_rowcol_counter.vcd