`default_nettype none
`timescale 1ns/1ps

/*
Deel Logica, Sieben
Testbench voor L_controller
Veel code hergebruikt van de andere testbenches
*/

module tb_L_controller ();
    
    localparam int CLK_PERIOD = 10;   // ns
    
    logic clk, reset_n, reset_controller, L_next_iter, address_max, col_1, row_0;
    logic L_idle, L_write_enable, L_copying, reset_address;
    logic [1:0] advance_grid; 
    mode_pkg::mode_e L_mode, d_mode;

    int errors = 0;

    L_controller dut (
        .clk(clk),
        .reset_n(reset_n),
        .reset_controller(reset_controller),
        .L_next_iter(L_next_iter),
        .L_mode(L_mode),
        .address_max(address_max),
        .col_1(col_1),
        .row_0(row_0),
        .L_idle(L_idle),
        .L_write_enable(L_write_enable),
        .L_copying(L_copying),
        .advance_grid(advance_grid),
        .reset_address(reset_address),
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
        row_0 = '0;
        col_1 = '0;
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

        row_0 = 1'b1;
        col_1 = 1'b1;
        step(2);

        check(dut.state === dut.TORUS, "advanced niet naar TORUS (1)");

        reset_controller = 1'b1;
        step(1);
        check(dut.state === dut.IDLE, "reset_controller werkt niet");
        reset_controller = '0;
        L_next_iter = 1'b1;

        // Tot hier geraakt met updaten

        step(3);
        check(dut.state === dut.TORUS, "advanced niet naar TORUS (2)");
                
        address_max = 1'b1;

        step(1);
        check(dut.state === dut.IDLE, "advanced niet naar IDLE vanuit TORUS");

        address_max = 1'b0;
        L_mode = mode_pkg::BOUNDED;

        step(3);
        check(dut.state === dut.BOUNDED, "advanced niet naar MOVE_T");

        address_max = 1'b1;

        step(1);
        check(dut.state === dut.IDLE, "advanced niet naar IDLE vanuit BOUNDED");

        // Test 2: controlesignalen
        L_mode = mode_pkg::TORUS;

        // IDLE
        check(dut.state === dut.IDLE, "check_controlesignalen IDLE gebeurt op andere state");     
        check(L_idle === 1'b1 && L_write_enable === 1'b0 && L_copying === 1'b0 && 
              advance_grid === 2'b00 && reset_address=== 1'b1 && d_mode === mode_pkg::TORUS, "controlesignalen IDLE zijn fout");

        L_next_iter = 1'b1;
        step(1);
        
        // COPY
        check(dut.state === dut.COPY, "check_controlesignalen COPY gebeurt op andere state");     
        check(L_idle === 1'b0 && L_write_enable === 1'b1 && L_copying === 1'b1 && 
              advance_grid === 2'b10 && reset_address=== 1'b0 && d_mode === mode_pkg::TORUS, "controlesignalen COPY zijn fout");

        step(1);

        // TORUS
        check(dut.state === dut.TORUS, "check_controlesignalen TORUS gebeurt op andere state");     
        check(L_idle === 1'b0 && L_write_enable === 1'b1 && L_copying === 1'b0 && 
              advance_grid === 2'b01 && reset_address=== 1'b0 && d_mode === mode_pkg::TORUS, "controlesignalen TORUS zijn fout");

        L_mode = mode_pkg::BOUNDED;
        step(3);

        // BOUNDED
        check(dut.state === dut.BOUNDED, "check_controlesignalen BOUNDED gebeurt op andere state");     
        check(L_idle === 1'b0 && L_write_enable === 1'b1 && L_copying === 1'b0 && 
              advance_grid === 2'b01 && reset_address=== 1'b0 && d_mode === mode_pkg::BOUNDED, "controlesignalen BOUNDED zijn fout");

        step(1);

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
