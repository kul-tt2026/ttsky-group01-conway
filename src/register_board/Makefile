VERILATOR = verilator
FLAGS = --binary --timing --top-module tb_register_board

simulate:
	$(VERILATOR) $(FLAGS) register_board.sv tb_register_board.sv
	./obj_dir/Vtb_register_board

clean:
	rm -rf obj_dir