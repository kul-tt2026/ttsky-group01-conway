IVERILOG = iverilog
FLAGS    = -g2012
SRCS = project.sv \
       logica/L_controller.sv logica/L_datapath.sv \
       logica/L_decider.sv logica/L_rowcol_counter.sv \
       logica/L_sweep_counter.sv logica/L_sweeper.sv \
	   logica/L_main.sv register_board/register_board.sv

simulate_project:
	$(IVERILOG) $(FLAGS) -o sim.out $(SRCS) tb_project.sv
	./sim.out

.PHONY: simulate_sim_speed
simulate_sim_speed:
	$(IVERILOG) $(FLAGS) -o sim.out sim_speed.sv tb_sim_speed.sv
	./sim.out

.PHONY: simulate_next_iter_countdown
simulate_next_iter_countdown:
	$(IVERILOG) $(FLAGS) -o sim.out sim_speed.sv next_iter_countdown.sv tb_next_iter_countdown.sv
	./sim.out

.PHONY: simulate_project_controller
simulate_project_controller:
	$(IVERILOG) $(FLAGS) -o sim.out project_controller.sv tb_project_controller.sv
	./sim.out

.PHONY: clean
clean:
	rm -f sim.out tb_project.vcd tb_sim_speed.vcd tb_next_iter_countdown.vcd tb_project_controller.vcd