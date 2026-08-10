`default_nettype none
`timescale 1ns/1ps

/*
Deel Logica, Sieben
Testbench voor L_sweep_counter
Veel code hergebruikt van tb_L_rowcol_counter
*/

module tb_L_sweep_counter ();

    localparam int CLK_PERIOD = 10;   // ns

    logic clk, reset_n, reset_sweep, advance_sweep;
    logic [3:0] sweep_number;
    logic read_ready;

    int errors = 0;

    // initiatie dut ('Device Under Test')
    L_sweep_counter dut (
        .clk(clk),
        .reset_n(reset_n),
        .reset_sweep(reset_sweep),
        .advance_sweep(advance_sweep),
        .sweep_number(sweep_number),
        .read_ready(read_ready)
    );

    // Klok
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Waveform
    initial begin
        $dumpfile("tb_L_sweep_counter.vcd");
        $dumpvars(0, tb_L_sweep_counter);
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
        // Alle inputs een bekende waarde geven voor de eerste klokflank.
        reset_n         = 1'b1;
        reset_sweep     = 1'b0;
        advance_sweep   = 1'b0;

        reset_n = 1'b0; // initatie zodat de counter uit de X state geraakt
        step(1);
        reset_n = 1'b1;

        step(2);
        check(sweep_number == '0, "sweep_number advanced ook al staat advance uit");

        advance_sweep   = 1'b1;
        step(3);
        check(sweep_number == 4'd3, "sweep_number advanced verkeerd (1)");
        check(read_ready == '0, "read ready is 1 terwijl die nul moet zijn");

        reset_n = 1'b0;
        step(1);
        check(sweep_number == '0, "reset_n werkt niet");
        
        reset_n = 1'b1;
        step(8);
        check(sweep_number == 4'd8, "sweep_number advanced verkeerd (2)");
        check(read_ready == 1'b1, "read ready is 0 terwijl die 1 moet zijn");

        reset_sweep = 1'b1;
        step(1);
        check(sweep_number == '0, "reset_sweep werkt niet");

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
