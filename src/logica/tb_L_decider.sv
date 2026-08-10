`default_nettype none
`timescale 1ns/1ps

/*
Deel Logica, Sieben
Testbench voor L_decider
Veel code hergebruikt van tb_L_sweep_counter
*/

module tb_L_decider ();

    localparam int CLK_PERIOD = 10;   // ns
    
    logic clk, reset_n, reset_decider, cel;
    logic [3:0] sweep_number;
    logic L_new_cel;

    int errors = 0;

    L_decider dut (
        .clk(clk),
        .reset_n(reset_n),
        .reset_decider(reset_decider),
        .cel(cel),
        .sweep_number(sweep_number),
        .L_new_cel(L_new_cel)
    );

    // Klok
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Waveform
    initial begin
        $dumpfile("tb_L_decider.vcd");
        $dumpvars(0, tb_L_decider);
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
        reset_n = 1'b0;
        reset_decider = 1'b0;
        cel = 1'b0;
        sweep_number = 4'b0;

        step(2); // zodat alles geïnitialiseerd is
        reset_n = 1'b1;
        check(L_new_cel === '0, "reset_n werkt niet");


        // Test 1: cel zelf is dood
        step(1);
        check(L_new_cel === '0, "decider werkt niet (1)");

        cel = 1'b1;
        sweep_number = 4'd1;
        step(1);
        check(L_new_cel === '0, "decider werkt niet (2)");

        cel = 1'b0;
        sweep_number = 4'd2;
        step(1);
        check(L_new_cel === '0, "decider werkt niet (3)");

        cel = 1'b1;
        sweep_number = 4'd3;
        step(1);
        check(L_new_cel === '0, "decider werkt niet (4)");

        cel = 1'b1;
        sweep_number = 4'd4;
        step(1);
        check(L_new_cel === 1'b1, "decider werkt niet (5)"); // exact drie buren

        cel = 1'b0;
        sweep_number = 4'd5;
        step(1);
        check(L_new_cel === 1'b1, "decider werkt niet (6)"); // nog steeds exact drie buren

        reset_decider = 1'b1;
        step(1);
        check(L_new_cel === 1'b0, "reset_decider werkt niet");
        reset_decider = 1'b0;

        // Test 2: cel zelf is levend

        cel = 1'b1;
        sweep_number = 4'd0;
        step(1);
        check(L_new_cel === '0, "decider werkt niet (7)");

        cel = 1'b1;
        sweep_number = 4'd1;
        step(1);
        check(L_new_cel === '0, "decider werkt niet (8)");

        cel = 1'b0;
        sweep_number = 4'd2;
        step(1);
        check(L_new_cel === '0, "decider werkt niet (9)");

        cel = 1'b1;
        sweep_number = 4'd3;
        step(1);
        check(L_new_cel === 1'b1, "decider werkt niet (10)"); // Twee buren

        cel = 1'b0;
        sweep_number = 4'd4;
        step(1);
        check(L_new_cel === 1'b1, "decider werkt niet (11)"); // nog steeds twee buren

        cel = 1'b1;
        sweep_number = 4'd5;
        step(1);
        check(L_new_cel === 1'b1, "decider werkt niet (12)"); // drie buren

        cel = 1'b1;
        sweep_number = 4'd6;
        step(1);
        check(L_new_cel === 1'b0, "decider werkt niet (13)");

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
