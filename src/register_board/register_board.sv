// input 
// reset_n == global reset
// data_in == pixel black or white (0 or 1)
// read_address == row and col coordinate for pixel that needs to be displayed
// write_address == row and col coordinate where new value gets saved
// write_enable == 1 if you want to write to a board
// active_board_read selects which board you read
// active_board_write selects which board you write to

// output 
// data_out == value of pixel from read address
// general: logic can write to a board, when its full active_board bitflips. The board thats just been written changes to read
// and the old read board can get new data written onto it.
// testing via cd src, cd register_board, make simulate in terminal 

/*
Origineel geschreven door Sander, licht aangepast door Sieben
Aanpassingen Sieben:
 - gezorgd dat je van één bord kunt lezen terwijl je op het andere schrijft
 - gezorgd dat je een ander aantal rijen en kolommen kan hebben
 - x en y hernoemd naar row en col
*/


`default_nettype none
`timescale 1ns/1ps
module register_board #(
    parameter int row_count = 8,  // aantal pirowels
    parameter int col_count = 8   // Werkt niet voor row_count of col_count = 1    
) (
    input logic clk,
    input logic reset_n,
    input logic data_in,
    input logic [row_bits - 1:0] read_address_row,
    input logic [col_bits - 1:0] read_address_col,
    input logic [row_bits - 1:0] write_address_row,
    input logic [col_bits - 1:0] write_address_col,
    input logic active_board_read,
    input logic active_board_write,
    input logic write_enable,
    output logic data_out
);

    localparam int row_bits = $clog2(row_count);
    localparam int col_bits = $clog2(col_count);

    reg board0 [row_count - 1:0][col_count - 1:0]; // grid
    reg board1 [row_count - 1:0][col_count - 1:0]; // previous grid

    integer row;
    integer col;

    always_ff @(posedge clk or negedge reset_n) begin 
        if (!reset_n) begin
            for (row=0; row < row_count; row++) begin
                for (col=0; col < col_count; col++) begin 
                    board0[row][col] <= 1'b0;
                    board1[row][col] <= 1'b0;
                end
            end
        end
        else begin
            if (write_enable) begin
                if (!active_board_write) 
                    board0[write_address_row][write_address_col] <= data_in;
                else
                    board1[write_address_row][write_address_col] <= data_in;
            end
        end
    end

    // combinatorisch lezen
    assign data_out = active_board_read ? board1[read_address_row][read_address_col] : board0[read_address_row][read_address_col];

endmodule

`default_nettype wire
