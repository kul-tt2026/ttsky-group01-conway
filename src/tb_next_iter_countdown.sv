`default_nettype none
`timescale 1ns/1ns

import sim_speed_pkg::*;

module tb_next_iter_countdown ();
    
    localparam int CLK_PERIOD = 10;   // ns

    localparam int CLOCK_CYCLES_PER_SECOND = 16; // Hz


    logic clk, reset_n, reset_countdown;
    speed_e speed;
    logic countdown_done;

    int errors = 0;

    // initiatie dut ('Device Under Test')
    next_iter_countdown #(
        .clock_cycles_per_second(CLOCK_CYCLES_PER_SECOND)
    ) dut (
        .clk(clk),
        .reset_n(reset_n),
        .reset(reset_countdown),
        .speed(speed),
        .countdown_done(countdown_done)
    );

    // Klok
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Waveform
    initial begin
        $dumpfile("tb_next_iter_countdown.vcd");
        $dumpvars(0, tb_next_iter_countdown);
    end

    // Watchdog
    initial begin
        #(CLK_PERIOD * 1000);
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
        reset_countdown = '0;
        speed = QUARTER_HZ;

        step(2);        
        check(countdown_done === 1'b0, "reset_n werkt niet");
        reset_n = 1'b1;

        step(CLOCK_CYCLES_PER_SECOND);
        check(countdown_done === 1'b0, "te vroeg countdown_done bij QUARTER HZ");

        step(CLOCK_CYCLES_PER_SECOND * 3);
        check(countdown_done === 1'b1, "countdown_done werkt niet bij QUARTER HZ");

        reset_countdown = 1'b1;
        step(1);
        check(countdown_done === 1'b0, "reset_countdown werkt niet (1)");
        reset_countdown = 1'b0;

        speed = HALF_HZ;
        step(CLOCK_CYCLES_PER_SECOND * 2);
        check(countdown_done === 1'b1, "countdown_done werkt niet bij HALF HZ");

        reset_countdown = 1'b1;
        step(1);
        check(countdown_done === 1'b0, "reset_countdown werkt niet (2)");
        reset_countdown = 1'b0;

        speed = ONE_HZ;
        step(CLOCK_CYCLES_PER_SECOND);
        check(countdown_done === 1'b1, "countdown_done werkt niet bij ONE HZ");

        reset_countdown = 1'b1;
        step(1);
        check(countdown_done === 1'b0, "reset_countdown werkt niet (3)");
        reset_countdown = 1'b0;

        speed = TWO_HZ;
        step(CLOCK_CYCLES_PER_SECOND / 2);
        check(countdown_done === 1'b1, "countdown_done werkt niet bij TWO HZ");

        reset_countdown = 1'b1;
        step(1);
        check(countdown_done === 1'b0, "reset_countdown werkt niet (4)");
        reset_countdown = 1'b0;

        speed = FOUR_HZ;
        step(CLOCK_CYCLES_PER_SECOND / 4);
        check(countdown_done === 1'b1, "countdown_done werkt niet bij FOUR HZ");


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