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
    parameter int row_count = 8,  // aantal pixels
    parameter int col_count = 8   // Werkt niet voor row_count of col_count = 1    
) (
    input logic clk,
    input logic reset_n,
    input logic L_reset, // gebruik ik enkel om reset_controller aan te drijven, want die reset dan ook het datapath
    input logic L_forward,
    input logic cel_out_pg,

    output logic L_idle,
    output logic [row_bits + col_bits - 1:0] L_address,
    output logic L_new_cel,
    output logic L_LD_cel_g,
    output logic L_LD_cel_pg
);

    localparam int row_bits = $clog2(row_count);
    localparam int col_bits = $clog2(col_count);

    // interne signalen
    logic advance_grid, reset_address, advance_sweep, reset_sweep, reset_decider;
    logic address_max, read_ready;

    L_controller u_L_controller (
        .clk(clk),
        .reset_n(reset_n),
        .reset_controller(L_reset),
        .L_forward(L_forward),
        .address_max(address_max),
        .read_ready(read_ready),
        .L_idle(L_idle),
        .L_LD_cel_pg(L_LD_cel_pg),
        .L_LD_cel_g(L_LD_cel_g),
        .advance_grid(advance_grid),
        .reset_address(reset_address),
        .advance_sweep(advance_sweep),
        .reset_sweep(reset_sweep),
        .reset_decider(reset_decider)
    );

    L_datapath #(
        .row_count(row_count),
        .col_count(col_count)
    ) u_L_datapath (
        .clk(clk),
        .reset_n(reset_n),
        .advance_grid(advance_grid),
        .reset_address(reset_address),
        .advance_sweep(advance_sweep),
        .reset_sweep(reset_sweep),
        .reset_decider(reset_decider),
        .read_ready(read_ready),
        .address_max(address_max),
        .cel_out_pg(cel_out_pg),
        .L_new_cel(L_new_cel),
        .L_address(L_address)
    );

    
endmodule

`default_nettype wire
