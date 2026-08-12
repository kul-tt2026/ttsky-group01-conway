`timescale 1ns/1ps
module tb_register_board_v2 ();

    localparam int ROWS = 8;
    localparam int COLS = 8;

    reg clk, reset_n, data_in, active_board_read, active_board_write, write_enable;
    reg [$clog2(ROWS)-1:0] read_address_row;
    reg [$clog2(COLS)-1:0] read_address_col;
    wire data_out;

    register_board_v2 #(
        .row_count(ROWS),
        .col_count(COLS)
    ) board_reg_v2 (
        .clk(clk),
        .reset_n(reset_n),
        .data_in(data_in),
        .active_board_read(active_board_read),
        .active_board_write(active_board_write),
        .write_enable(write_enable),
        .read_address_row(read_address_row),
        .read_address_col(read_address_col),
        .data_out(data_out)
    );

    always begin 
        #12.5 clk = ~clk;
    end
    
    integer i;
    integer j;
    integer k;

    initial begin
        $dumpfile("tb_register_board_v2.vcd");
        $dumpvars(0, tb_register_board_v2);
        reset_n = 1;
        #25;
        clk = 1;
        reset_n = 0;
        #25;
        reset_n = 1;
        write_enable = 0;
        active_board_read = 0;
        active_board_write = 0;
        data_in = 0;
        read_address_row = 0;
        read_address_col = 0;
        #25;
        
        for (i=0;i<ROWS*COLS;i++) begin 
            write_enable = 1;
            if(i%2==0) begin
                data_in = 1;
            end
            else begin 
                data_in = 0;
            end
            #50;
            write_enable = 0;
            #50;
        end

        for (j=0;j<ROWS;j++) begin
            read_address_row = read_address_row + 1;
            for (k=0;k<COLS;k++) begin
                read_address_col = read_address_col + 1;
                #50;
            end 
            read_address_col = 0;
            
        end
        #50;
        reset_n = 0;
        #50;
        reset_n = 1;
        write_enable = 1;
        data_in = 0;
        read_address_col = 0;
        read_address_row = 0;
        #500;
        

        $finish;
    end
endmodule 