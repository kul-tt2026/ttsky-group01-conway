`default_nettype none
`timescale 1ns/1ps

/*
Deel Logica, Sieben
Testbench voor L_sweeper
Veel code hergebruikt van tb_L_rowcol_counter
*/

module tb_L_sweeper ();

    localparam int ROWS       = 4;
    localparam int COLS       = 3;
    localparam int CLK_PERIOD = 10;   // ns

    logic [$clog2(ROWS)-1:0] row;
    logic [$clog2(COLS)-1:0] col;
    logic [3:0] sweep_number;
    logic [$clog2(ROWS) + $clog2(COLS) - 1:0] L_address;

    int errors = 0;
    
    L_sweeper #(
        .row_count(ROWS),
        .col_count(COLS)
    ) dut (
        .row(row),
        .col(col),
        .sweep_number(sweep_number),
        .L_address(L_address)
    );

    // Hulpfunctie (danku Claude Opus 5)
    task automatic apply(input int r, input int c, input int s);
        row          = r[$bits(row)-1:0];
        col          = c[$bits(col)-1:0];
        sweep_number = s[3:0];
        #1;   // laat de combinatorische logica settelen
    endtask

    // Andere hulpfunctie (heb ik wel zelf geschreven)(oké heb ik wel zelf een al bestaande functie van tb_rowcol_counter aangepast)
    task automatic check_address(input logic [$clog2(ROWS) + $clog2(COLS) - 1:0] address);
        if (L_address !== address) begin
            errors++;
            $error("[%0t] -- verwacht L_address=%0b, kreeg L_address=%0b, bij row=%0d, col=%0d, sweep_number=%0d",
                   $time, address, L_address, row, col, sweep_number);
        end
    endtask

    // Tests
    initial begin
        /*
        De conventie voor de sweep is:
            8 1 2
            7 0 3
            6 5 4
        */
        
        // Eerste test in een centraal vakje

        apply(1,1,0);   // rij, kolom, sweep
        check_address({2'd1, 2'd1}); // address is {rij, kolom}

        apply(1,1,1);   
        check_address({2'd0, 2'd1});

        apply(1,1,2);   
        check_address({2'd0, 2'd2});

        apply(1,1,3);   
        check_address({2'd1, 2'd2});

        apply(1,1,4);   
        check_address({2'd2, 2'd2});

        apply(1,1,5);   
        check_address({2'd2, 2'd1});

        apply(1,1,6);   
        check_address({2'd2, 2'd0});

        apply(1,1,7);   
        check_address({2'd1, 2'd0});

        apply(1,1,8);   
        check_address({2'd0, 2'd0});

        apply(1,1,9);   
        check_address({2'd1, 2'd1});    // bij sweep_number hoger dan acht moet het terug naar het centrale vakje gaan

        apply(1,1,10);   
        check_address({2'd1, 2'd1});

        // Test: vakje linksboven

        apply(0,0,0);   
        check_address({2'd0, 2'd0});

        apply(0,0,1);   
        check_address({2'd3, 2'd0});

        apply(0,0,2);   
        check_address({2'd3, 2'd1});

        apply(0,0,6);   
        check_address({2'd1, 2'd2});

        apply(0,0,7);   
        check_address({2'd0, 2'd2});

        apply(0,0,8);   
        check_address({2'd3, 2'd2});


        // Test: vakje rechtsonder

        apply(3,2,0);   
        check_address({2'd3, 2'd2});

        apply(3,2,2);   
        check_address({2'd2, 2'd0});

        apply(3,2,3);   
        check_address({2'd3, 2'd0});

        apply(3,2,4);   
        check_address({2'd0, 2'd0});

        apply(3,2,5);   
        check_address({2'd0, 2'd2});

        apply(3,2,6);   
        check_address({2'd0, 2'd1});


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
