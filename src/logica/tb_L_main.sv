`default_nettype none
`timescale 1ns / 1ps

/*
Deel Sieben, Logica
Deze testbench voegt L_main samen met wat geheugen
Wordt voornamelijk uitgevoerd in python, zie test_L_main.py
*/

module tb_L_main ();
    
    localparam int CLK_PERIOD = 10;   // ns
    localparam int ROWS       = 12;
    localparam int COLS       = 16;

    localparam int row_bits = $clog2(ROWS);
    localparam int col_bits = $clog2(COLS);

    // L_main
    logic clk, reset_n, L_reset, L_next_iter;
    logic L_idle, L_new_cel, L_copying, L_write_enable, L_toggle_read;
    logic [row_bits-1:0] L_row;  
    logic [col_bits-1:0] L_col;
    mode_pkg::mode_e L_mode;
    // Reg
    logic data_in, data_out, active_board_read, active_board_write, toggle_read, write_enable;
    logic [7:0] neighbours;
    logic [row_bits-1:0] address_row;  
    logic [col_bits-1:0] address_col;
    // Hulpjes
    logic init, init_write_data, init_write_enable;
    logic [row_bits-1:0] init_row;  
    logic [col_bits-1:0] init_col;

    L_main #(.row_count(ROWS), .col_count(COLS)) u_L_main (
        .clk(clk),
        .reset_n(reset_n),
        .L_reset(L_reset),
        .L_next_iter(L_next_iter),
        .L_mode(L_mode),
        .old_cel(data_out),
        .neighbours(neighbours),
        .L_idle(L_idle),
        .L_new_cel(L_new_cel),
        .L_copying(L_copying),
        .L_write_enable(L_write_enable),
        .L_row(L_row),
        .L_col(L_col),
        .L_toggle_read(L_toggle_read)
    );

    register_board #(
        .row_count(ROWS),
        .col_count(COLS)
    ) u_register_board (
        .clk(clk),
        .reset_n(reset_n),
        .data_in(data_in),
        .active_board_read(active_board_read),
        .active_board_write(active_board_write),
        .write_enable(write_enable),
        .read_address_row(address_row),
        .read_address_col(address_col),
        .write_address_row(address_row),
        .write_address_col(address_col),
        .toggle_read(toggle_read),
        .data_out(data_out),
        .neighbour_out(neighbours)
    );

    always_comb begin

        if(init) begin
            data_in = init_write_data;
            write_enable = 1'b1;
            active_board_read = 1'b0;
            active_board_write = 1'b0;

            {address_row, address_col} = {init_row, init_col};

            toggle_read = '0;
        end
        else begin

            if(L_copying) data_in = data_out;
            else data_in = L_new_cel;

            // Grids: 0 is next grid, 1 is previous grid
            active_board_read = !L_copying;
            active_board_write = L_copying;

            write_enable = L_write_enable;

            {address_row, address_col} = {L_row, L_col};

            toggle_read = L_toggle_read;

        end

    end

    // Klok
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Waveform
    initial begin
        $dumpfile("tb_L_main.vcd");
        $dumpvars(0, tb_L_main);
    end


endmodule

`default_nettype wire
