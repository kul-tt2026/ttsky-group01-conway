VERILATOR = verilator
FLAGS =  --binary --timing --top-module --trace tb_register_board
FLAG =  --binary --timing --trace

# Voor Sieben thuis:
IVERILOG = iverilog
FLAGS_I = -g2012

simulate:
	$(VERILATOR) $(FLAGS) register_board.sv tb_register_board.sv
	./obj_dir/Vtb_register_board

simulate_v2:
	$(VERILATOR) $(FLAG) --top-module tb_register_board_v2 register_board.sv tb_register_board_v2.sv
	./obj_dir/Vtb_register_board_v2

simulate_reg_Sieben:
	$(IVERILOG) $(FLAGS_I) -o sim.out register_board.sv tb_register_board.sv
	./sim.out

clean:
	rm -rf obj_dir