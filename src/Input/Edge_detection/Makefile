VERILATOR = verilator
FLAGS = --binary --timing --trace --top-module tb_Edge_detection

simulate:
	$(VERILATOR) $(FLAGS) Edge_detection.sv tb_Edge_detection.sv
	./obj_dir/Vtb_Edge_detection

clean:
	rm -rf obj_dir