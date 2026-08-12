`default_nettype none
`timescale 1ns/1ps


module tb_project_controller ();
    
    localparam int CLK_PERIOD = 10;   // ns
    
    logic clk, reset_n, start, next_iter, L_idle;
    logic L_reset, nic_reset, reset_speed, simulation_running, next_iter_busy;

    int errors = 0;

    project_controller dut (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .next_iter(next_iter),
        .L_idle(L_idle),
        .L_reset(L_reset),
        .nic_reset(nic_reset),
        .reset_speed(reset_speed),
        .simulation_running(simulation_running),
        .next_iter_busy(next_iter_busy)
    );

    // Klok
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Waveform
    initial begin
        $dumpfile("tb_project_controller.vcd");
        $dumpvars(0, tb_project_controller);
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
        start = '0;
        next_iter = '0;
        L_idle = '0;

        // Test 1: next state logica
        step(1);
        reset_n = 1'b1;

        check(dut.state === dut.START, "reset_n werkt niet");

        step(2);
        check(dut.state === dut.START, "state advanced terwijl dat niet mag (1)");

        start = 1'b1;
        step(3);
        start = 1'b0;

        check(dut.state === dut.DISPLAY, "advanced niet naar DISPLAY (1)");

        next_iter = 1'b1;
        step(2);
        check(dut.state === dut.NEXT_ITER, "advanced niet naar NEXT_ITER");
        next_iter = 1'b0;

        L_idle = 1'b1;
        step(1);
        check(dut.state === dut.DISPLAY, "advanced niet naar DISPLAY (2)");
        L_idle = 1'b0;

        reset_n = '0;
        step(1);
        reset_n = 1'b1;

        // Test 2: controlesignalen

        // START
        check(dut.state === dut.START, "check_controlesignalen START gebeurt op andere state");     
        check(L_reset === 1'b1 && nic_reset === 1'b1 && reset_speed === 1'b1 && 
              simulation_running === 1'b0 && next_iter_busy === 1'b0,
               "controlesignalen START zijn fout");

        start = 1'b1;
        step(1);
        
        // COPY
        check(dut.state === dut.DISPLAY, "check_controlesignalen DISPLAY gebeurt op andere state");     
        check(L_reset === 1'b0 && nic_reset === 1'b0 && reset_speed === 1'b0 && 
              simulation_running === 1'b1 && next_iter_busy === 1'b0,
               "controlesignalen DISPLAY zijn fout");
    
        next_iter = 1'b1;
        step(1);

        // NEXT_ITER
        check(dut.state === dut.NEXT_ITER, "check_controlesignalen NEXT_ITER gebeurt op andere state");       
        check(L_reset === 1'b0 && nic_reset === 1'b0 && reset_speed === 1'b0 && 
              simulation_running === 1'b1 && next_iter_busy === 1'b1,
               "controlesignalen NEXT_ITER zijn fout");

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
