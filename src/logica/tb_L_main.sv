`default_nettype none
`timescale 1ns / 1ps

/*
Deel Sieben, Logica
Deze testbench voegt L_main samen met wat geheugen
Wordt voornamelijk uitgevoerd in python, zie test_L_main.py
*/

module tb_L_main ();
    
    localparam int CLK_PERIOD = 10;   // ns
    localparam int ROWS       = 8;
    localparam int COLS       = 8;

    localparam int row_bits = $clog2(ROWS);
    localparam int col_bits = $clog2(COLS);

    // L_main
    logic clk, reset_n, L_reset, L_next_iter, cel_out_pg;
    logic L_idle, L_new_cel, L_LD_cel_g, L_LD_cel_pg;
    logic [row_bits + col_bits - 1:0] L_address;
    // Reg
    logic data_in, data_out, active_board_read, active_board_write, write_enable;
    logic [row_bits-1:0] address_row;  
    logic [col_bits-1:0] address_col;
    // Hulpjes
    logic init;

    L_main #(.row_count(ROWS), .col_count(COLS)) u_L_main (
        .clk(clk),
        .reset_n(reset_n),
        .L_reset(L_reset),
        .L_next_iter(L_next_iter),
        .cel_out_pg(cel_out_pg),
        .L_idle(L_idle),
        .L_new_cel(L_new_cel),
        .L_LD_cel_g(L_LD_cel_g),
        .L_LD_cel_pg(L_LD_cel_pg),
        .L_address(L_address)
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
        .data_out(data_out)
    );

    always_comb begin
        // Initialisatie
        if (init) begin 
            active_board_write = 0;
        end
        // De simulatie runt zelf
        else begin           
            address_row = L_address[row_bits + col_bits - 1:col_bits];
            address_col = L_address[col_bits - 1:0];

            // Grids: 0 is grid, 1 is previous_grid
            if (L_LD_cel_pg) begin  // COPY MODE
                active_board_write = 1;
                active_board_read = 0;
                write_enable = 1;
                data_in = data_out;
            end 
            else if (L_LD_cel_g) begin
                active_board_write = 0;
                active_board_read = 1;
                write_enable = 1;
                data_in = L_new_cel;
            end
            else begin
                active_board_write = 0; // Don't care
                active_board_read = 1;
                write_enable = 0;
                data_in = 0; // Don't care
            end

            if (active_board_read == 1) cel_out_pg = data_out;
                else cel_out_pg = 0; // Don't care
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
