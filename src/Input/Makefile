VERILATOR = verilator
FLAGS = --binary --timing --trace

TB ?= tb_Debouncer

SOURCES = Debouncer.sv

simulate:
	$(VERILATOR) $(FLAGS) --top-module $(TB) $(SOURCES) $(TB).sv
	./obj_dir/V$(TB)

clean:
	rm -rf obj_dir
	rm -f *.vcd
	cd /workspaces/ttsky-group01-conway