# Deel Sieben, logica

IVERILOG = iverilog
FLAGS    = -g2012

simulate_L_rowcol_counter:
	$(IVERILOG) $(FLAGS) -o sim.out L_rowcol_counter.sv tb_L_rowcol_counter.sv
	./sim.out

simulate_L_sweep_counter:
	$(IVERILOG) $(FLAGS) -o sim.out L_sweep_counter.sv tb_L_sweep_counter.sv
	./sim.out

simulate_L_sweeper:
	$(IVERILOG) $(FLAGS) -o sim.out L_sweeper.sv tb_L_sweeper.sv
	./sim.out

simulate_L_decider:
	$(IVERILOG) $(FLAGS) -o sim.out L_decider.sv tb_L_decider.sv
	./sim.out

simulate_L_controller:
	$(IVERILOG) $(FLAGS) -o sim.out L_controller.sv tb_L_controller.sv
	./sim.out

clean:
	rm -f sim.out tb_L_rowcol_counter.vcd tb_L_sweep_counter.vcd tb_L_sweeper.vcd tb_L_decider.vcd tb_L_controller.vcd