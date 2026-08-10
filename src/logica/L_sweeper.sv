`default_nettype none
`timescale 1ns/1ps

/*
Deel Logica, Sieben
Deze module conveerteerd row, col en sweep_number naar een adres
voor het geheugen, in {row, col} formaat. 
Deze module is COMBINATORISCH

De conventie voor de sweep is:
    8 1 2
    7 0 3
    6 5 4

Als het sweep_number hoger is dan acht, returnen we het adres van
de middelste pixel (0 in de conventie).

De rij boven de bovenste rij is de onderste, etc.
*/

module L_sweeper #(
    parameter int row_count = 8,  // aantal pixels
    parameter int col_count = 8   // Werkt niet voor row_count of col_count = 1
) (
    input logic [row_bits-1:0] row,
    input logic [col_bits-1:0] col,
    input logic [3:0] sweep_number,

    output logic [row_bits + col_bits - 1:0] L_address
);

    localparam int row_bits = $clog2(row_count);
    localparam int col_bits = $clog2(col_count);

    logic [row_bits:0] sweep_row; // één extra bit zodat we slim kunnen omgaan met de wrap
    logic [col_bits:0] sweep_col; 

    always_comb begin
        sweep_row = {1'b0, row};
        sweep_col = {1'b0, col};

        case (sweep_number)
            4'd0: ; // verander niets, dus gewoon row & col
            4'd1: sweep_row = sweep_row - 1'b1;
            4'd2: begin
                sweep_row = sweep_row - 1'b1;
                sweep_col = sweep_col + 1'b1;
            end 
            4'd3: sweep_col = sweep_col + 1'b1;
            4'd4: begin
                sweep_row = sweep_row + 1'b1;
                sweep_col = sweep_col + 1'b1;
            end 
            4'd5: sweep_row = sweep_row + 1'b1;
            4'd6: begin
                sweep_row = sweep_row + 1'b1;
                sweep_col = sweep_col - 1'b1;
            end 
            4'd7: sweep_col = sweep_col - 1'b1;
            4'd8: begin
                sweep_row = sweep_row - 1'b1;
                sweep_col = sweep_col - 1'b1;
            end 
            default: ; // verander niets, dus gewoon row & col
        endcase

        // Wrapping: een beetje miserie in het geval de breedte/hoogte geen macht van twee is

        // Wrapping in de ←↑ richting
        if(sweep_row === '1) sweep_row = (row_bits+1)'(row_count - 1);
        if(sweep_col === '1) sweep_col = (col_bits+1)'(col_count - 1);

        // Wrapping in de ↓→ richting
        if(sweep_row >= (row_bits+1)'(row_count)) sweep_row = '0;
        if(sweep_col >= (col_bits+1)'(col_count)) sweep_col = '0;

    end

    assign L_address = {sweep_row[row_bits-1:0], sweep_col[col_bits-1:0]};

endmodule

`default_nettype wire
