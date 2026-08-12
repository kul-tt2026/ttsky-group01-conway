`default_nettype none
`timescale 1ns/1ps

import sim_speed_pkg::*;

module tb_sim_speed ();
    
    localparam int CLK_PERIOD = 10;   // ns

    logic clk, reset_n, reset_speed, increase, decrease;
    logic [2:0] speed;

    int errors = 0;

    // initiatie dut ('Device Under Test')
    sim_speed dut (
        .clk(clk),
        .reset_n(reset_n),
        .reset(reset_speed),
        .increase(increase),
        .decrease(decrease),
        .speed(speed)
    );

    // Klok
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Waveform
    initial begin
        $dumpfile("tb_sim_speed.vcd");
        $dumpvars(0, tb_sim_speed);
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
        // Initiële waardes
        reset_n = '0;
        reset_speed = '0;
        increase = '0;
        decrease = '0;

        step(2);
        reset_n = 1'b1;
        step(1);

        check(speed === QUARTER_HZ, "reset_n werkt niet goed");

        increase = 1'b1;

        step(1);
        check(speed === HALF_HZ, "increase werkt niet goed (1)");

        step(1);
        check(speed === ONE_HZ, "increase werkt niet goed (2)");

        step(1);
        check(speed === TWO_HZ, "increase werkt niet goed (3)");

        step(1);
        check(speed === FOUR_HZ, "increase werkt niet goed (4)");

        step(1);
        check(speed === FOUR_HZ, "increase werkt niet goed (5)");

        increase = 1'b0;

        step(3);

        decrease = 1'b1;

        step(2);
        check(speed === ONE_HZ, "decrease werkt niet goed");

        decrease = 1'b0;
        reset_speed = 1'b1;

        step(1);
        check(speed === QUARTER_HZ, "reset_speed werkt niet goed");


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
