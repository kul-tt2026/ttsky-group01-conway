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
    input logic advance_sweep,
    input logic reset_sweep,
    input logic reset_decider,
    input logic cel_out_pg,
    input mode_pkg::mode_e d_mode,

    output logic address_max,
    output logic read_ready,
    output logic [$clog2(row_count) + $clog2(col_count) - 1:0] L_address,
    output logic L_new_cel
);

    localparam int row_bits = $clog2(row_count);
    localparam int col_bits = $clog2(col_count);

    // Interne verbindingen
    logic [row_bits - 1:0] row;
    logic [col_bits - 1:0] col;
    logic [3:0] sweep_number;
    logic row_max, row_0, col_max, col_0;

    L_rowcol_counter #(
        .row_count(row_count),
        .col_count(col_count)
    ) u_L_rowcol_counter (
        .clk(clk),
        .reset_n(reset_n),
        .advance_grid(advance_grid),
        .reset_address(reset_address),
        .row(row),
        .col(col),
        .row_0(row_0),
        .col_0(col_0),
        .row_max(row_max),
        .col_max(col_max),
        .address_max(address_max)
    );

    L_sweep_counter u_L_sweep_counter (
        .clk(clk),
        .reset_n(reset_n),
        .reset_sweep(reset_sweep),
        .advance_sweep(advance_sweep),
        .sweep_number(sweep_number),
        .read_ready(read_ready)
    );

    L_sweeper #(
        .row_count(row_count),
        .col_count(col_count)
    ) u_L_sweeper (
        .row(row),
        .col(col),
        .sweep_number(sweep_number),
        .L_address(L_address)
    );

    L_decider u_L_decider (
        .clk(clk),
        .reset_n(reset_n),
        .reset_decider(reset_decider),
        .cel(cel_out_pg),
        .sweep_number(sweep_number),
        .d_mode(d_mode),
        .row_0(row_0),
        .col_0(col_0),
        .row_max(row_max),
        .col_max(col_max),
        .L_new_cel(L_new_cel)
    );

endmodule

`default_nettype wire
