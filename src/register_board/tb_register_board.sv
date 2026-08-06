`timescale 1ns/1ps
module tb_register_board ();

    localparam int ROWS = 8;
    localparam int COLS = 8;

    reg clk, reset_n, data_in, active_board_read, active_board_write, write_enable;
    reg [$clog2(ROWS)-1:0] read_address_row, write_address_row;
    reg [$clog2(COLS)-1:0] read_address_col, write_address_col;
    wire data_out;

    register_board #(
        .row_count(ROWS),
        .col_count(COLS)
    ) board_reg (
        .clk(clk),
        .reset_n(reset_n),
        .data_in(data_in),
        .active_board_read(active_board_read),
        .active_board_write(active_board_write),
        .write_enable(write_enable),
        .read_address_row(read_address_row),
        .read_address_col(read_address_col),
        .write_address_row(write_address_row),
        .write_address_col(write_address_col),
        .data_out(data_out)
    );

    always begin 
        #1 clk = ~clk;
    end

    // Waveform
    initial begin
        $dumpfile("tb_register_board.vcd");
        $dumpvars(0, tb_register_board);
    end

    initial begin
        clk = 1;
        reset_n = 1;
        #5;
        reset_n = 0;
        write_enable = 0;
        active_board_read = 0;
        active_board_write = 0;
        data_in = 0;
        read_address_row = 0;
        read_address_col = 0;
        write_address_row = 0;
        write_address_col = 0;
        #5;
        // test reset_n
        reset_n = 1;
        write_enable = 1;
        #5;
        if (data_out)
            $display("expected 0 received %b", data_out);
        else
            $display("passed");
        #2;
        // test writing 1 coordinate
        write_address_row = 3;
        write_address_col = 4;
        active_board_write = 1;
        data_in = 1;
        @(posedge clk);
        #2;
        active_board_read = 1;
        read_address_row = 3;
        read_address_col = 4;
        #2;
        if (data_out)
            $display("passed");
        else
            $display("expected 1 received %b", data_out);
        #2;
        active_board_write = 0;
        write_address_row = 1;
        write_address_col = 1;
        data_in = 1;
        @(posedge clk);
        #2        
        write_address_row = 3;
        write_address_col = 4;
        data_in = 1;
        #2;
        active_board_read = 0;
        read_address_row = 3;
        read_address_col = 4;
        #2;
        if (data_out)
            $display("passed");
        else
            $display("expected 1 received %b", data_out);
        read_address_row = 1;
        read_address_col = 1;
        #2;
        if (data_out)
            $display("passed");
        else
            $display("expected 1 received %b", data_out);
        #2;
        write_enable = 0;
        read_address_row = 7;
        read_address_col = 7;
        #2;
        if (~data_out)
            $display("passed");
        else
            $display("expected 0 received %b", data_out);
        #2;
        read_address_row = 7;
        read_address_col = 0;
        #2;
        if (~data_out)
            $display("passed");
        else
            $display("expected 0 received %b", data_out);
        #2;
        active_board_read = 0;
        #2;
        read_address_row = 0;
        read_address_col = 7;
        #2;
        if (~data_out)
            $display("passed");
        else
            $display("expected 0 received %b", data_out);
        #2;
        read_address_row = 3;
        read_address_col = 4;
        #2;
        if (data_out)
            $display("passed");
        else
            $display("expected 1 received %b", data_out);
        #2;
        active_board_read = 1;
        read_address_row = 3;
        read_address_col = 4;
        #2;
        if (data_out)
            $display("passed");
        else
            $display("expected 1 received %b", data_out);
        #2;
        reset_n = 0;
        #2;
        read_address_row = 3;
        read_address_col = 4;
        #2;
        if (~data_out)
            $display("passed");
        else
            $display("expected 0 received %b", data_out);
        #2;
        active_board_read = 0;
        read_address_row = 0;
        read_address_col = 7;
        #2;
        if (~data_out)
            $display("passed");
        else
            $display("expected 0 received %b", data_out);

        $finish;
    end
endmodule 