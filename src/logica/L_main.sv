`default_nettype none
`timescale 1ns/1ps

/*
Deel Logica, Sieben
Deze file brengt alles samen van Logica
Er is geen testbench tb_L_controller, deze wordt samen met het geheugen getest
Per iteratie heeft deze 12×row_count×col_count klokcycli nodig.
Voor 16x16 is dat 3072 klokcycli
Indien nodig kan ik nog proberen om daar 25% af te doen, maar dat lijkt me helemaal niet nodig
*/

module L_main #(
    parameter int row_count = 8,  // aantal cellen
    parameter int col_count = 8   // Werkt niet voor row_count of col_count = 1    
) (
    input logic clk,
    input logic reset_n,
    input logic L_reset, // doet hetzelfde als reset_n. Wel twee cyclussen hoog laten staan: eerst reset je de controller, dan reset de controller het datapad
    input logic L_next_iter, // start de berekening van de volgende iteratie van de simulatie. Is klaar wanneer L_idle weer hoog is
    input mode_pkg::mode_e L_mode, // TORUS of BOUNDED
    input logic old_cel,
    input logic [7:0] neighbours,

    output logic L_idle,
    output logic [$clog2(row_count) - 1:0] L_row,
    output logic [$clog2(col_count) - 1:0] L_col,
    output logic L_new_cel,
    output logic L_write_enable,
    output logic L_copying,
    output logic [1:0] advance_grid
);

    localparam int row_bits = $clog2(row_count);
    localparam int col_bits = $clog2(col_count);

    // interne signalen
    logic reset_address, row_0, col_1;
    logic address_max, read_ready;
    mode_pkg::mode_e d_mode;

    L_controller u_L_controller (
        .clk(clk),
        .reset_n(reset_n),
        .reset_controller(L_reset),
        .L_next_iter(L_next_iter),
        .L_mode(L_mode),
        .address_max(address_max),
        .row_0(row_0),
        .col_1(col_1),
        .L_idle(L_idle),
        .L_write_enable(L_write_enable),
        .L_copying(L_copying),
        .advance_grid(advance_grid),
        .reset_address(reset_address),
        .d_mode(d_mode)
    );

    L_datapath #(
        .row_count(row_count),
        .col_count(col_count)
    ) u_L_datapath (
        .clk(clk),
        .reset_n(reset_n),
        .advance_grid(advance_grid),
        .reset_address(reset_address),
        .d_mode(d_mode),
        .row_0(row_0),
        .col_1(col_1),
        .address_max(address_max),
        .old_cel(old_cel),
        .neighbours(neighbours),
        .L_new_cel(L_new_cel),
        .L_row(L_row),
        .L_col(L_col)
    );

    
endmodule

`default_nettype wire
