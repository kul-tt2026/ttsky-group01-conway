`default_nettype none  // Tip van Claude
`timescale 1ns/1ps // dit is enkel voor simulatie

/*
Deel Logica, Sieben
Deze module houd een index bij voor een row×col grid
Verder output die enkele nuttige utilities over row en col
*/

module L_rowcol_counter #(
    parameter int row_count = 8,   // aantal cellen
    parameter int col_count = 8   // Werkt niet voor row_count of col_count = 1
) (
    input logic clk,
    input logic reset_n,        // active low:  reset bij 0
    input logic reset_address,  // active high: reset bij 1
    input logic advance_grid,

    output logic [$clog2(row_count)-1:0] row,
    output logic [$clog2(col_count)-1:0] col,
    output logic row_0,
    output logic col_0,
    output logic row_max,
    output logic col_max,
    output logic address_max
);
    
    localparam int row_bits = $clog2(row_count);
    localparam int col_bits = $clog2(col_count);

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            row <= '0;
            col <= '0;
        end
        else if (reset_address) begin
            row <= '0;
            col <= '0;
        end
        else if (advance_grid) begin
            // col wordt eerst afgegaan, dan row. Dus eerst naar rechts, dan volgende rij
            if (address_max) begin
                row <= '0;
                col <= '0;
            end
            else if (col_max) begin
                row <= row + 1'b1;
                col <= '0;
            end
            else begin
                col <= col + 1'b1;
            end
        end
    end

    assign row_0 = (row == '0);
    assign col_0 = (col == '0);

    assign row_max = (row == row_bits'(row_count - 1));
    assign col_max = (col == col_bits'(col_count - 1));

    assign address_max = (row_max && col_max);

endmodule

`default_nettype wire // zodat het terug in orde is voor de andere files
