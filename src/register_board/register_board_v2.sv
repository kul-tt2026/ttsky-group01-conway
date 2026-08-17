/*
Nieuwe versie geheugen analoog aan register board enkel kan je nu sequentieel schrijven door write enable te togglen. 
De waarde van data_in wordt naar de positie geschreven en er wordt 1 positie opgeschoven met een teller.
We starten op 0,0.
*/

/*
Origineel geschreven door Sander, licht aangepast door Sieben
Aanpassingen Sieben:
 - gezorgd dat je van één bord kunt lezen terwijl je op het andere schrijft
 - gezorgd dat je een ander aantal rijen en kolommen kan hebben
 - x en y hernoemd naar row en col
*/


`default_nettype none
`timescale 1ns/1ps
module register_board_v2 #(
    parameter int row_count = 8,  // aantal pirowels
    parameter int col_count = 8   // Werkt niet voor row_count of col_count = 1    
) (
    input logic clk,
    input logic reset_n,
    input logic data_in,
    input logic [row_bits - 1:0] read_address_row,
    input logic [col_bits - 1:0] read_address_col,
    input logic active_board_read,
    input logic active_board_write,
    input logic [1:0] direction,
    input logic write_enable,
    output logic data_out
);

    localparam int row_bits = $clog2(row_count);
    localparam int col_bits = $clog2(col_count);
    localparam int board_size = row_count*col_count;
    localparam int address_bits = $clog2(board_size);

    logic [address_bits-1:0] read_address;
    logic [$clog2(row_count*col_count)-1:0] write_counter;
    reg board0 [row_count*col_count-1:0]; // grid
    reg board1 [row_count*col_count-1:0]; // previous grid

    integer reset_count;

    always_ff @(posedge clk or negedge reset_n) begin 
        if (!reset_n) begin
            write_counter <= 0;
            for(reset_count=0; reset_count<row_count*col_count;reset_count++)begin
                    board0[reset_count] <= 1'b0;
                    board1[reset_count] <= 1'b0;
            end
        end
        else begin
            if (write_enable) begin
                if (!active_board_write) 
                    board0[write_counter] <= data_in;
                else
                    board1[write_counter] <= data_in;
                if (write_counter<$clog2(board_size)'(board_size-1)) begin
                    write_counter <= write_counter + 1'b1;
                end
                else begin
                    write_counter <= 0;
                end
            end
        end
    end

    always_comb begin
        read_address = address_bits'(read_address_row*col_count+int'(read_address_col));
    end
    // combinatorisch lezen
    assign data_out = active_board_read ? board1[read_address] : board0[read_address];

endmodule

`default_nettype wire
