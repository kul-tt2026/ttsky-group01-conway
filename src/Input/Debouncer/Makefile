VERILATOR = verilator
FLAGS = --binary --timing --trace --top-module tb_Debouncer

simulate:
	$(VERILATOR) $(FLAGS) Debouncer.sv tb_Debouncer.sv
	./obj_dir/Vtb_Debouncer

clean:
	rm -rf obj_dir