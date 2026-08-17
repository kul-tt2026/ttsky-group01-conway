`timescale 1ns/1ps

module tb_register_board ();

    localparam int ROWS = 8;
    localparam int COLS = 8;
    localparam int BOARD_SIZE = ROWS * COLS;

    reg clk;
    reg reset_n;
    reg data_in;
    reg temp;

    reg active_board_read;
    reg toggle_read;
    reg active_board_write;
    reg write_enable;

    reg [$clog2(ROWS)-1:0] read_address_row;
    reg [$clog2(COLS)-1:0] read_address_col;
    reg [$clog2(ROWS)-1:0] write_address_row;
    reg [$clog2(COLS)-1:0] write_address_col;
    logic [8:0] neighbour_out;

    wire data_out;


    register_board #(
        .row_count(ROWS),
        .col_count(COLS)
    ) board_reg (
        .clk(clk),
        .reset_n(reset_n),

        .data_in(data_in),

        .active_board_read(active_board_read),
        .toggle_read(toggle_read),
        .active_board_write(active_board_write),
        .write_enable(write_enable),

        .read_address_row(read_address_row),
        .read_address_col(read_address_col),

        .write_address_row(write_address_row),
        .write_address_col(write_address_col),

        .neighbour_out(neighbour_out),
        .data_out(data_out)
    );

    integer i;
    integer j;

    // Clock
    always begin
        #1 clk = ~clk;
    end


    // Waveform
    initial begin
        $dumpfile("tb_register_board.vcd");
        $dumpvars(0, tb_register_board);
    end


    initial begin

        // Initial values
        clk = 1;
        reset_n = 1;

        data_in = 0;

        active_board_read = 0;
        toggle_read = 0;
        active_board_write = 0;
        write_enable = 0;

        read_address_row = 0;
        read_address_col = 0;

        write_address_row = 0;
        write_address_col = 0;


        // --------------------------------------------------
        // RESET
        // --------------------------------------------------

        #5;

        reset_n = 0;

        #5;

        reset_n = 1;

        #2;


        // --------------------------------------------------
        // TEST 1:
        // Na reset moet board0 leeg zijn
        // --------------------------------------------------

        active_board_read = 0;

        read_address_row = 0;
        read_address_col = 0;

        #2;

        if (!data_out)
            $display("TEST 1 PASSED");
        else
            $display("TEST 1 FAILED: expected 0, received %b", data_out);


        // --------------------------------------------------
        // TEST 2:
        // Schrijf 1 naar board0 op positie (3,4)
        // --------------------------------------------------

        write_enable = 1;
        data_in = 1;

        write_address_row = 3;
        write_address_col = 4;

        @(posedge clk);
        #1;

        write_enable = 0;

        active_board_read = 0;

        read_address_row = 3;
        read_address_col = 4;

        #1;

        if (data_out)
            $display("TEST 2 PASSED");
        else
            $display("TEST 2 FAILED: expected 1, received %b", data_out);


        // --------------------------------------------------
        // TEST 3:
        // Controleer dat andere cellen nog 0 zijn
        // --------------------------------------------------

        read_address_row = 0;
        read_address_col = 0;

        #2;

        if (!data_out)
            $display("TEST 3 PASSED");
        else
            $display("TEST 3 FAILED: expected 0, received %b", data_out);


        // --------------------------------------------------
        // TEST 4:
        // Schrijf nog een 1 naar board0 op (1,1)
        // --------------------------------------------------

        write_enable = 1;
        data_in = 1;

        write_address_row = 1;
        write_address_col = 1;

        @(posedge clk);
        #1;

        write_enable = 0;

        read_address_row = 1;
        read_address_col = 1;

        #1;

        if (data_out)
            $display("TEST 4 PASSED");
        else
            $display("TEST 4 FAILED: expected 1, received %b", data_out);


        // --------------------------------------------------
        // TEST 5:
        // Controleer (7,7) = 0
        // --------------------------------------------------

        read_address_row = 7;
        read_address_col = 7;

        #2;

        if (!data_out)
            $display("TEST 5 PASSED");
        else
            $display("TEST 5 FAILED: expected 0, received %b", data_out);


        // --------------------------------------------------
        // TEST 6:
        // Controleer (3,4) = 1
        // --------------------------------------------------

        read_address_row = 3;
        read_address_col = 4;

        #2;

        if (data_out)
            $display("TEST 6 PASSED");
        else
            $display("TEST 6 FAILED: expected 1, received %b", data_out);
        // --------------------------------------------------
        // TEST 7:
        // active_board_write Board1
        // --------------------------------------------------
        active_board_write = 1;
        #1;
        for (i=ROWS-1;i>=0;i--) begin
            for (j=COLS-1;j>=0;j--) begin
                read_address_col = $clog2(COLS)'(j);
                read_address_row = $clog2(ROWS)'(i);
                #1;
                data_in = data_out;
                @(posedge clk);
                #1;
            end
        end
        #1;
        for (i=0;i<ROWS;i++) begin
            for (j=0;j<COLS;j++) begin
                active_board_read = 0;
                read_address_row = $clog2(ROWS)'(i);
                read_address_col = $clog2(COLS)'(j);
                #1;
                temp = data_out;
                #1;
                active_board_read = 1;
                $display("board0 = %b en board1 = %b",temp,data_out);
                if (temp == data_out) begin
                    $display("PASSED");
                end
                else
                    $display("FAILED"); begin
                end
                #1;
                toggle_read = 1;
                #1;
                toggle_read = 0;
            end
        end
        

        // --------------------------------------------------
        // TEST 8:
        // RESET opnieuw testen
        // --------------------------------------------------

        reset_n = 0;

        #2;

        active_board_read = 0;

        read_address_row = 3;
        read_address_col = 4;

        #2;

        if (!data_out)
            $display("TEST 8 PASSED");
        else
            $display("TEST 8 FAILED: expected 0, received %b", data_out);
        

        // --------------------------------------------------
        // EINDE
        // --------------------------------------------------

        $display("--------------------------------");
        $display("TESTBENCH FINISHED");
        $display("--------------------------------");

        $finish;

    end

endmodule