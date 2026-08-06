`default_nettype none
`timescale 1ns/1ps

/*
Snelle testbench om initiële logica-implementatie van Sieben te testen
*/

module tb_project ();

    localparam int CLK_PERIOD = 10;   // ns

    //inputs
    logic [7:0] ui_in, uio_in;
    logic clk, ena, rst_n;
    //outputs
    logic [7:0] uo_out, uio_out, uio_oe;

    int errors = 0;

    tt_um_conwaysgameoflife u_conway (
        .ui_in(ui_in),  // adres in {row, col}
        .uio_in(uio_in), /* 7:6 irrelevant; 5 L_forward, 4 data_in, 3 active_board_read,
                             2 active_board_write, 1 write_enable, 0 logica_enable */
        .clk(clk),
        .ena(ena),
        .rst_n(rst_n),
        .uo_out(uo_out),    // 7:2 irrelevant, 1 L_idle; 0 data_out
        .uio_out(uio_out),  // irrelevant
        .uio_oe(uio_oe)
    );

    // Klok
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Waveform
    initial begin
        $dumpfile("tb_project.vcd");
        $dumpvars(0, tb_project);
    end

    // Watchdog
    initial begin
        #(CLK_PERIOD * 6170);
        $error("TIMEOUT: testbench is niet klaargeraakt");
        $finish;
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

        ena = 1'b1;
        ui_in = '0; // adres {row, col}
        uio_in = '0; /* 7:6 irrelevant; 5 L_forward, 4 data_in, 3 active_board_read,
                            2 active_board_write, 1 write_enable, 0 logica_enable */

        // reset
        rst_n = '0;
        step(5);
        rst_n = 1'b1;

        // initialisatie: drie volle vakjes die een ——  ←→ | gaan herhalen
    
        uio_in[1] = 1'b1; // write enable, active board is al het goeie (0 = grid)
        uio_in[4] = 1'b1; // data_in

        ui_in = 8'b0001_0000;
        step(1);

        ui_in = 8'b0001_0001;
        step(1);

        ui_in = 8'b0001_0010;
        step(1);

        uio_in[1] = 1'b0; // write enable
        uio_in[4] = 1'b0; // data_in

        // Simulatie één iteratie laten doen
        uio_in[0] = 1'b1; // logica_enable
        uio_in[5] = 1'b1; // L_forward
        step(1);
        uio_in[5] = 1'b0;

        do step(1); while (!uo_out[1]); // wachten op L_idle

        uio_in[0] = 1'b0; // logica_enable

        // Verificatie
        ui_in = 8'b0001_0000;
        step(1);
        check(uo_out[0] === 1'b0, "linkse bit is één, terwijl die nul moest worden");

        ui_in = 8'b0001_0010;
        step(1);
        check(uo_out[0] === 1'b0, "rechtse bit is één, terwijl die nul moest worden");

        ui_in = 8'b0001_0001;
        step(1);
        check(uo_out[0] === 1'b1, "midden bit is nul, terwijl die één moest blijven");

        ui_in = 8'b0000_0001;
        step(1);
        check(uo_out[0] === 1'b1, "boven bit is nul, terwijl die één moest worden");

        ui_in = 8'b0010_0001;
        step(1);
        check(uo_out[0] === 1'b1, "onder bit is nul, terwijl die één moest worden");

        // Nog een iteratie verdergaan

        uio_in[0] = 1'b1; // logica_enable
        uio_in[5] = 1'b1; // L_forward
        step(1);
        uio_in[5] = 1'b0;

        do step(1); while (!uo_out[1]); // wachten op L_idle

        uio_in[0] = 1'b0; // logica_enable

        // Nog eens verificatie

        ui_in = 8'b0001_0000;
        step(1);
        check(uo_out[0] === 1'b1, "linkse bit is nul, terwijl die één moest worden");

        ui_in = 8'b0001_0010;
        step(1);
        check(uo_out[0] === 1'b1, "rechtse bit is nul, terwijl die één moest worden");

        ui_in = 8'b0001_0001;
        step(1);
        check(uo_out[0] === 1'b1, "midden bit is nul, terwijl die één moest blijven");

        ui_in = 8'b0000_0001;
        step(1);
        check(uo_out[0] === 1'b0, "boven bit is één, terwijl die nul moest worden");

        ui_in = 8'b0010_0001;
        step(1);
        check(uo_out[0] === 1'b0, "onder bit is één, terwijl die nul moest worden");

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