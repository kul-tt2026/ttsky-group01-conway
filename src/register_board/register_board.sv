/*
Board0 is het algemene board waar input naar schrijft, vga uit leest en logica naar schrijft en uit leest. Dit board 
is random acces voor zowel write als read. Board1 wordt door logica gebruikt als bufferboard en is een shift register. 
Er is een write_enable die hoog moet staan om te kunnen schrijven. Active_board- read en write bepalen in welk board geschreven
of gelezen wordt. Toggle read shift het register board1 naar links om de volgende cel te kunnen uitlezen (beginnend bij (0,0)). 
Als write_enable en copy hoog zijn dan wordt het register board1 naar rechts geshift en wordt data_in op de eerste plaats gezet
(beginnende met de laatste cel).
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
module register_board #(
    parameter int row_count = 8,  // aantal pirowels
    parameter int col_count = 8   // Werkt niet voor row_count of col_count = 1    
) (
    input logic clk,
    input logic reset_n,
    input logic data_in,
    input logic [$clog2(row_count) - 1:0] read_address_row,
    input logic [$clog2(col_count) - 1:0] read_address_col,
    input logic [$clog2(row_count) - 1:0] write_address_row,
    input logic [$clog2(col_count) - 1:0] write_address_col,
    input logic active_board_read,
    input logic toggle_read,
    input logic active_board_write,
    input logic write_enable,
    output logic data_out,
    output logic [7:0] neighbour_out
);

    localparam int row_bits = $clog2(row_count);
    localparam int col_bits = $clog2(col_count);
    localparam [col_bits-1:0] COL_COUNT = col_bits'(col_count-1);

    logic board0 [row_count - 1:0][col_count - 1:0]; // grid
    logic [row_count*col_count-1:0] board1 ; // previous grid

    integer row;
    integer col;

    always_ff @(posedge clk or negedge reset_n) begin 
        if (!reset_n) begin
            for (row=0; row < row_count; row++) begin
                for (col=0; col < col_count; col++) begin 
                    board0[row][col] <= 1'b0;
                    board1[row*col_count + col] <= 1'b0;
                end
            end
        end
        else begin
            if (write_enable) begin
                if(active_board_write && ~toggle_read) begin
                    board1 <= {data_in, board1[row_count*col_count-1:1]};
                end
                else begin
                    board0[write_address_row][write_address_col] <= data_in;
                end
            end
            if (toggle_read && ~active_board_write) begin
                board1 <= {board1[0], board1[row_count*col_count-1:1]};
            end
        end
    end

    // combinatorisch lezen
    always_comb begin
        if(~active_board_read) begin
            data_out = board0[read_address_row][read_address_col];
            neighbour_out = 0;
        end
        else begin
            data_out = board1[0];
            neighbour_out = {/*7*/board1[(row_count-1)*col_count-1], /*6*/board1[row_count*col_count-1], /*5*/board1[col_count-1],
                             /*4*/board1[col_count], /*3*/board1[col_count+1], /*2*/board1[1],
                             /*1*/board1[(row_count-1)*col_count + 1], /*0*/board1[(row_count-1)*col_count]};
            // fix voor wrapping: verticale wrapping werkt zowieso, horizontale moet gefixt worden (voor cellen aan de rand)
            if (read_address_col == '0) begin
                /*
                alt_7 = 6
                alt_6 = 5
                alt_5 = 2*col_count - 1
                omdat de positie van de buren onbelangrijk is, is er enkel een alt_7 = 2*col_count - 1 (want de normale 7 is ongeldig)
                */
                neighbour_out[7] = /*alt_7*/ board1[2*col_count-1];
            end                    
            if (read_address_col == col_bits'(col_count-1)) begin
                /*
                alt_3 = 2
                alt_2 = 1
                alt_1 = (row_count-2)*col_count + 1
                voor de zelfde reden als hierboven is er enkel een alt_3 = (row_count-2)*col_count + 1
                */
                neighbour_out[3] = /*alt_3*/ board1[(row_count-2)*col_count + 1];
            end 

        end
    end

endmodule

`default_nettype wire
