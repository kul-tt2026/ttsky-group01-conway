`timescale 1ns/1ps
module tb_register_board ();
    reg clk, reset_n, data_in, active_board, write_enable;
    reg [2:0] read_address_x, read_address_y, write_address_x, write_address_y;
    wire data_out;

        register_board board_reg (
            .clk(clk),
            .reset_n(reset_n),
            .data_in(data_in),
            .active_board(active_board),
            .write_enable(write_enable),
            .read_address_x(read_address_x),
            .read_address_y(read_address_y),
            .write_address_x(write_address_x),
            .write_address_y(write_address_y),
            .data_out(data_out)
        );
    always begin 
        #1 clk = ~clk;
    end
    initial begin
        clk = 1;
        reset_n = 1;
        #5;
        reset_n = 0;
        write_enable = 0;
        active_board = 0;
        data_in = 0;
        read_address_x = 0;
        read_address_y = 0;
        write_address_x = 0;
        write_address_y = 0;
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
        write_address_x = 3;
        write_address_y = 4;
        data_in = 1;
        @(posedge clk);
        #2;
        active_board = 1;
        read_address_x = 3;
        read_address_y = 4;
        #2;
        if (data_out)
            $display("passed");
        else
            $display("expected 1 received %b", data_out);
        #2;
        write_address_x = 1;
        write_address_y = 1;
        data_in = 1;
        @(posedge clk);
        write_address_x = 3;
        write_address_y = 4;
        data_in = 1;
        #2;
        active_board = 0;
        read_address_x = 3;
        read_address_y = 4;
        #2;
        if (data_out)
            $display("passed");
        else
            $display("expected 1 received %b", data_out);
        read_address_x = 1;
        read_address_y = 1;
        #2;
        if (data_out)
            $display("passed");
        else
            $display("expected 1 received %b", data_out);
        #2;
        read_address_x = 7;
        read_address_y = 7;
        #2;
        if (~data_out)
            $display("passed");
        else
            $display("expected 0 received %b", data_out);
        #2;
        read_address_x = 7;
        read_address_y = 0;
        #2;
        if (~data_out)
            $display("passed");
        else
            $display("expected 0 received %b", data_out);
        #2;
        active_board = 0;
        #2;
        read_address_x = 0;
        read_address_y = 7;
        #2;
        if (~data_out)
            $display("passed");
        else
            $display("expected 0 received %b", data_out);
        #2;
        read_address_x = 3;
        read_address_y = 4;
        #2;
        if (data_out)
            $display("passed");
        else
            $display("expected 1 received %b", data_out);
        #2;
        active_board = 1;
        read_address_x = 3;
        read_address_y = 4;
        #2;
        if (data_out)
            $display("passed");
        else
            $display("expected 1 received %b", data_out);
        #2;
        reset_n = 0;
        #2;
        read_address_x = 3;
        read_address_y = 4;
        #2;
        if (~data_out)
            $display("passed");
        else
            $display("expected 0 received %b", data_out);
        #2;
        active_board = 0;
        read_address_x = 0;
        read_address_y = 7;
        #2;
        if (~data_out)
            $display("passed");
        else
            $display("expected 0 received %b", data_out);

        $finish;
    end
endmodule 