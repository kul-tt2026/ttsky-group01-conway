`default_nettype none
`timescale 1ns/1ps

/*
Deel Logica, Sieben
Testbench voor L_rowcol_counter
Deels geschreven door Claude Opus 5 als voorbeeld voor Sieben hoe je een testbench schrijft
*/

module tb_L_rowcol_counter ();

    localparam int ROWS       = 4;
    localparam int COLS       = 3;
    localparam int CLK_PERIOD = 10;   // ns

    logic clk, reset_n, reset_address;
    logic [1:0] advance_grid;
    logic [$clog2(ROWS)-1:0] row;
    logic [$clog2(COLS)-1:0] col;
    logic row_0, col_0, col_1, row_max, col_max, address_max;

    int errors = 0;

    // initiatie dut ('Device Under Test')
    L_rowcol_counter #(
        .row_count(ROWS),
        .col_count(COLS)
    ) dut (
        .clk(clk),
        .reset_n(reset_n),
        .reset_address(reset_address),
        .advance_grid(advance_grid),
        .row(row),
        .col(col),
        .row_0(row_0),
        .col_0(col_0),
        .col_1(col_1),
        .row_max(row_max),
        .col_max(col_max),
        .address_max(address_max)
    );

    // Klok
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Waveform
    initial begin
        $dumpfile("tb_L_rowcol_counter.vcd");
        $dumpvars(0, tb_L_rowcol_counter);
    end

    // Watchdog
    initial begin
        #(CLK_PERIOD * 500);
        $error("TIMEOUT: testbench is niet klaargeraakt");
        $fatal(1, "TIMEOUT: testbench is niet klaargeraakt");
    end

    // Drie hulpfuncties van Claude Opus 5
    task automatic step(input int n = 1);
        repeat (n) @(negedge clk);
    endtask

    task automatic check(input bit cond, input string msg);
        if (!cond) begin
            errors++;
            $error("[%0t] %s", $time, msg);
        end
    endtask

    task automatic check_rc(input int exp_row, input int exp_col, input string msg);    // Merk op: exp_row & exp_col zijn integers, je kan dus gewoon 3 schrijven
        if (row !== exp_row[$bits(row)-1:0] || col !== exp_col[$bits(col)-1:0]) begin
            errors++;
            $error("[%0t] %s -- verwacht row=%0d col=%0d, kreeg row=%0d col=%0d",
                   $time, msg, exp_row, exp_col, row, col);
        end
    endtask

    // Tests
    initial begin
        // Alle inputs een bekende waarde geven voor de eerste klokflank.
        reset_n       = 1'b1;
        reset_address = 1'b0;
        advance_grid  = 2'b0;

        step(2);
        reset_n = 1'b0;
        step(2);
        check_rc(0, 0, "reset_n werkt niet");
        check(row_0 && col_0 && !col_1, "row_0/col_0 kloppen niet tijdens reset_n");
        check(!row_max && !col_max && !address_max, "row_max/col_max/address_max zijn hoog wanneer ze laag moeten zijn");

        reset_n       = 1'b1;
        advance_grid  = 2'b01;
        step(1);
        check_rc(0, 1, "advance_grid  werkt niet (1)");
        check(col_1, "col_1 werkt niet");

        step(4);
        check_rc(1, 2, "advance_grid  werkt niet (2)");
        check(col_max, "col_max werkt niet");
        check(!row_0 && !col_0 && !col_1, "row_0/col_0 zijn hoog wanneer ze laag moeten zijn");

        reset_address = 1'b1;
        step(1);
        check_rc(0, 0,"reset_address werkt niet");
       
        reset_address = 1'b0;
        step(9);
        check_rc(3, 0, "advance_grid  werkt niet (3)");
        check(row_max && !col_max && !address_max, "row_max/col_max/address_max werken niet (1)");

        step(2);
        check_rc(3, 2, "advance_grid  werkt niet (4)");
        check(row_max && col_max && address_max, "row_max/col_max/address_max werken niet (2)");

        advance_grid = 2'b10;

        step(1);
        check_rc(3,1, "advance_grid werkt niet in de achterwaartse richting");



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
