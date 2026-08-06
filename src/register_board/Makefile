VERILATOR = verilator
FLAGS = -g2012 --binary --timing --top-module tb_register_board

# Voor Sieben thuis:
IVERILOG = iverilog
FLAGS_I = -g2012

simulate:
	$(VERILATOR) $(FLAGS) register_board.sv tb_register_board.sv
	./obj_dir/Vtb_register_board

simulate_reg_Sieben:
	$(IVERILOG) $(FLAGS_I) -o sim.out register_board.sv tb_register_board.sv
	./sim.out

clean:
	rm -rf obj_dir