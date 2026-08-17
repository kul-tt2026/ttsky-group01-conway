`default_nettype none
`timescale 1ns/1ps

/*
Deel Logica, Sieben
Testbench voor L_controller
Veel code hergebruikt van de andere testbenches
*/

module tb_L_controller ();
    
    localparam int CLK_PERIOD = 10;   // ns
    
    logic clk, reset_n, reset_controller, L_next_iter, address_max, read_ready;
    logic L_idle, L_LD_cel_pg, L_LD_cel_g, advance_grid, reset_address, advance_sweep, reset_sweep, reset_decider;
    mode_pkg::mode_e L_mode, d_mode;

    int errors = 0;

    L_controller dut (
        .clk(clk),
        .reset_n(reset_n),
        .reset_controller(reset_controller),
        .L_next_iter(L_next_iter),
        .L_mode(L_mode),
        .address_max(address_max),
        .read_ready(read_ready),
        .L_idle(L_idle),
        .L_LD_cel_pg(L_LD_cel_pg),
        .L_LD_cel_g(L_LD_cel_g),
        .advance_grid(advance_grid),
        .reset_address(reset_address),
        .advance_sweep(advance_sweep),
        .reset_sweep(reset_sweep),
        .reset_decider(reset_decider),
        .d_mode(d_mode)
    );

    // Klok
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Waveform
    initial begin
        $dumpfile("tb_L_controller.vcd");
        $dumpvars(0, tb_L_controller);
    end

    // Watchdog
    initial begin
        #(CLK_PERIOD * 500);
        $error("TIMEOUT: testbench is niet klaargeraakt");
        $fatal(1, "TIMEOUT: testbench is niet klaargeraakt");
    end

    // Hulpfuncties
    task automatic step(input int n = 1);
        repeat (n) @(negedge clk);
    endtask

    task automatic check(input bit cond, input string msg);
        if (!cond) begin
            errors++;
            $error("[%0t] %s", $time, msg);
        end
    endtask

    // Tests
    initial begin

        reset_n = '0;
        reset_controller = '0;
        L_next_iter = '0;
        address_max = '0;
        read_ready = '0;
        L_mode = mode_pkg::TORUS;

        // Test 1: next state logica
        step(1);
        reset_n = 1'b1;

        check(dut.state === dut.IDLE, "reset_n werkt niet");

        step(2);
        check(dut.state === dut.IDLE, "state advanced terwijl dat niet mag (1)");

        L_next_iter = 1'b1;
        step(3);
        L_next_iter = 1'b0;

        check(dut.state === dut.COPY, "advanced niet naar COPY");

        address_max = 1'b1;
        step(2);

        check(dut.state === dut.READ_T, "advanced niet naar READ_T (1)");

        reset_controller = 1'b1;
        step(1);
        check(dut.state === dut.IDLE, "reset_controller werkt niet");
        reset_controller = '0;
        L_next_iter = 1'b1;

        step(2);
        check(dut.state === dut.READ_T, "advanced niet naar READ_T (2)");
        
        address_max = '0;
        read_ready = 1'b1;

        step(1);
        check(dut.state === dut.WRITE_T, "advanced niet naar WRITE_T (1)");

        step(1);
        check(dut.state === dut.MOVE_T, "advanced niet naar MOVE_T");

        step(1);
        check(dut.state === dut.READ_T, "advanced niet naar READ_T (3)");

        address_max = 1'b1;
        // read_ready is al 1

        step(1);
        check(dut.state === dut.WRITE_T, "advanced niet naar WRITE_T (2)");

        step(1);
        check(dut.state === dut.IDLE, "advanced niet naar IDLE vanuit WRITE_T");
        
        
        address_max = '0;
        read_ready = '0;

        // Ga naar COPY
        L_next_iter = 1'b1;
        step(1);
        L_next_iter = 1'b0;

        address_max = 1'b1;
        L_mode = mode_pkg::BOUNDED;
        step(2);

        check(dut.state === dut.READ_B, "advanced niet naar READ_B (1)");
        
        address_max = '0;
        read_ready = 1'b1;

        step(1);
        check(dut.state === dut.WRITE_B, "advanced niet naar WRITE_B (1)");

        step(1);
        check(dut.state === dut.MOVE_B, "advanced niet naar MOVE_B");

        step(1);
        check(dut.state === dut.READ_B, "advanced niet naar READ_B (2)");

        address_max = 1'b1;
        // read_ready is al 1

        step(1);
        check(dut.state === dut.WRITE_B, "advanced niet naar WRITE_B (2)");

        step(1);
        check(dut.state === dut.IDLE, "advanced niet naar IDLE vanuit WRITE_B");



        // Test 2: controlesignalen
        L_mode = mode_pkg::TORUS;

        // IDLE
        check(dut.state === dut.IDLE, "check_controlesignalen IDLE gebeurt op andere state");     
        check(L_idle === 1'b1 && L_LD_cel_pg === 1'b0 && L_LD_cel_g === 1'b0 && 
              advance_grid === 1'b0 && reset_address=== 1'b1 && advance_sweep === 1'b0 && 
              reset_sweep === 1'b1 && reset_decider === 1'b1 && d_mode === mode_pkg::TORUS, "controlesignalen IDLE zijn fout");

        L_next_iter = 1'b1;
        step(1);
        
        // COPY
        check(dut.state === dut.COPY, "check_controlesignalen COPY gebeurt op andere state");     
        check(L_idle === 1'b0 && L_LD_cel_pg === 1'b1 && L_LD_cel_g === 1'b0 && 
              advance_grid === 1'b1 && reset_address=== 1'b0 && advance_sweep === 1'b0 && 
              reset_sweep === 1'b1 && reset_decider === 1'b1 && d_mode === mode_pkg::TORUS, "controlesignalen COPY zijn fout");

        step(1);

        // READ_T
        check(dut.state === dut.READ_T, "check_controlesignalen READ_T gebeurt op andere state");     
        check(L_idle === 1'b0 && L_LD_cel_pg === 1'b0 && L_LD_cel_g === 1'b0 && 
              advance_grid === 1'b0 && reset_address=== 1'b0 && advance_sweep === 1'b1 && 
              reset_sweep === 1'b0 && reset_decider === 1'b0 && d_mode === mode_pkg::TORUS, "controlesignalen READ_T zijn fout");

        address_max = 1'b0;
        step(1);

        // WRITE_T
        check(dut.state === dut.WRITE_T, "check_controlesignalen WRITE_T gebeurt op andere state");     
        check(L_idle === 1'b0 && L_LD_cel_pg === 1'b0 && L_LD_cel_g === 1'b1 && 
              advance_grid === 1'b1 && reset_address=== 1'b0 && advance_sweep === 1'b0 && 
              reset_sweep === 1'b1 && reset_decider === 1'b1 && d_mode === mode_pkg::TORUS, "controlesignalen WRITE_T zijn fout");

        step(1);

        // MOVE_T
        check(dut.state === dut.MOVE_T, "check_controlesignalen MOVE_T gebeurt op andere state");     
        check(L_idle === 1'b0 && L_LD_cel_pg === 1'b0 && L_LD_cel_g === 1'b0 && 
              advance_grid === 1'b0 && reset_address=== 1'b0 && advance_sweep === 1'b1 && 
              reset_sweep === 1'b0 && reset_decider === 1'b0 && d_mode === mode_pkg::TORUS, "controlesignalen MOVE_T zijn fout");



        // Einde
        if (errors == 0) begin
            $display("=== PASS ===");
            $finish;
        end
        else begin
            $fatal(1, "=== FAIL: %0d fout(en) ===", errors);
        end        
    end

endmodule

`default_nettype wire
