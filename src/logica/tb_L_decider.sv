`default_nettype none
`timescale 1ns/1ps

/*
Deel Logica, Sieben
Testbench voor L_decider
Veel code hergebruikt van tb_L_sweep_counter
*/

module tb_L_decider ();

    localparam int CLK_PERIOD = 10;   // ns
    
    logic clk, reset_n, cel, row_0, row_max, col_0, col_max;
    logic [7:0] neighbours;
    mode_pkg::mode_e d_mode;
    logic L_new_cel;

    int errors = 0;

    L_decider dut (
        .clk(clk),
        .reset_n(reset_n),
        .cel(cel),
        .neighbours(neighbours),
        .d_mode(d_mode),
        .row_0(row_0),
        .row_max(row_max),
        .col_0(col_0),
        .col_max(col_max),
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
        cel = 1'b0;
        neighbours = '0;
        d_mode = mode_pkg::TORUS;
        row_0 = '0;
        row_max = '0;
        col_0 = '0;
        col_max = '0;
    

        step(2); // zodat alles geïnitialiseerd is
        reset_n = 1'b1;
        check(L_new_cel === '0, "reset_n werkt niet");


        // Test 1: cel zelf is dood
        
        neighbours = 8'b0001_1000;
        step(1);
        check(L_new_cel === '0, "decider werkt niet (1)");

        // Test 2: cel zelf is levend

        cel = 1'b1;
        neighbours = 8'b1010_1010;
        step(1);
        check(L_new_cel === '0, "decider werkt niet (2)");

        // Test 3: cel zelf is levend

        cel = 1'b1;
        neighbours = 8'b0100_0110;
        step(1);
        check(L_new_cel === 1'b1, "decider werkt niet (3)");


        // Test 4: cel zelf is dood, aan de rand, bounded mode
        d_mode = mode_pkg::BOUNDED;
        row_0 = 1'b1;
        col_0 = 1'b1; // linkerbovenhoek, dus 0 1 5 6  mogen niet pakken

        cel = 1'b0;
        neighbours = 8'b1111_1111;
        step(1);
        check(L_new_cel === 1'b1, "decider werkt niet (4)");

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
