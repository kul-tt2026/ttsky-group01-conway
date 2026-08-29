`default_nettype none
`timescale 1ns/1ps

/*
Deel Logica, Sieben
Het datapath hangt de andere "niet-FSM" delen van logica aan elkaar
Hier is geen testbench voor
*/

module L_datapath #(
    parameter int row_count = 8,  // aantal cellen
    parameter int col_count = 8   // Werkt niet voor row_count of col_count = 1
) (
    input logic clk,
    input logic reset_n,
    input logic advance_grid,
    input logic reset_address,
    input logic old_cel,
    input logic [7:0] neighbours,
    input mode_pkg::mode_e d_mode,

    output logic address_max,
    output logic [$clog2(row_count) - 1:0] L_row,
    output logic [$clog2(col_count) - 1:0] L_col,
    output logic L_new_cel
);

    localparam int row_bits = $clog2(row_count);
    localparam int col_bits = $clog2(col_count);

    // Interne verbindingen
    logic row_0, row_max, col_0, col_max;

    L_rowcol_counter #(
        .row_count(row_count),
        .col_count(col_count)
    ) u_L_rowcol_counter (
        .clk(clk),
        .reset_n(reset_n),
        .advance_grid(advance_grid),
        .reset_address(reset_address),
        .row(L_row),
        .col(L_col),
        .row_0(row_0),
        .col_0(col_0),
        .row_max(row_max),
        .col_max(col_max),
        .address_max(address_max)
    );

    L_decider u_L_decider (
        .clk(clk),
        .reset_n(reset_n),
        .cel(old_cel),
        .neighbours(neighbours),
        .d_mode(d_mode),
        .row_0(row_0),
        .col_0(col_0),
        .row_max(row_max),
        .col_max(col_max),
        .L_new_cel(L_new_cel)
    );

endmodule

`default_nettype wire
