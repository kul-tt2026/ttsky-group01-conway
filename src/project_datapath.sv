`default_nettype none
`timescale 1ns/1ps

import sim_speed_pkg::*;  // Als de terminal hier errors over geeft: zorg dat sim_speed vóór deze module staat in de laadvolgorde

module project_datapath #(
    parameter int row_count = 16,
    parameter int col_count = 12
) (
    input logic clk,
    input logic reset_n,
    input logic L_reset,
    input logic nic_reset,
    input logic reset_speed,
    input logic simulation_running,
    input logic next_iter_busy,

    input logic button_up, 
    input logic button_down,
    input logic button_left,
    input logic button_right,
    input logic button_set,
    input logic button_start,

    input logic ena,
    input  logic [7:0] ui_in,    // Dedicated inputs
    output logic [7:0] uo_out,   // Dedicated outputs
    input  logic [7:0] uio_in,   // IOs: Input path
    output logic [7:0] uio_out,  // IOs: Output path
    output logic [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)

    output logic start,
    output logic next_iter,
    output logic L_idle
);

localparam int row_bits = $clog2(row_count);
localparam int col_bits = $clog2(col_count);

// Interne wires
speed_e speed;
logic increase, decrease, reset_countdown, countdown_done;

sim_speed u_sim_speed (
    .clk(clk),
    .reset_n(reset_n),
    .reset(reset_speed),
    .increase(increase),
    .decrease(decrease),

    .speed(speed)
);

assign reset_countdown = nic_reset || next_iter;

next_iter_countdown u_next_iter_countdown (
    .clk(clk),
    .reset_n(reset_n),
    .reset(reset_countdown),
    .speed(speed),

    .countdown_done(countdown_done)
);

// nog interne wires
logic cel_out_pg, L_new_cel, L_LD_cel_g, L_LD_cel_pg;
logic [row_bits + col_bits - 1:0] L_address;
logic next_iter_allowed;

assign next_iter = next_iter_allowed && countdown_done;

L_main #(
    .row_count(row_count),
    .col_count(col_count)
) u_L_main (
    .clk(clk),
    .reset_n(reset_n),
    .L_reset(L_reset),
    .L_next_iter(next_iter),
    .cel_out_pg(cel_out_pg),

    .L_idle(L_idle),
    .L_address(L_address),
    .L_new_cel(L_new_cel),
    .L_LD_cel_g(L_LD_cel_g),
    .L_LD_cel_pg(L_LD_cel_pg)
);

// meer interne wires
logic [row_bits-1:0] input_write_address_row;
logic [col_bits-1:0] input_write_address_col;
logic input_write_value;

Input #(
    .ROW_COUNT(row_count),
    .COL_COUNT(col_count)
) u_input (
    .clk(clk),
    .reset_n(reset_n),
    .button_up(button_up),
    .button_down(button_down),
    .button_left(button_left),
    .button_right(button_right),
    .button_set(button_set),
    .button_start(button_start),

    .write_address_row(input_write_address_row),
    .write_address_col(input_write_address_col),
    .write_value(input_write_value),
    .start(start)
    // TODO geef cursorpos aan vga
);

// nog meer interne wires
logic data_in, active_board_read, active_board_write, write_enable, data_out;
logic [row_bits-1:0] read_address_row, write_address_row;
logic [col_bits-1:0] read_address_col, write_address_col;

always_comb begin
    if (next_iter_busy) begin
        read_address_row = L_address[row_bits + col_bits - 1:col_bits];
        read_address_col = L_address[col_bits-1:0];
        
        write_enable = L_LD_cel_g || L_LD_cel_pg;

        write_address_row = L_address[row_bits + col_bits - 1:col_bits];
        write_address_col = L_address[col_bits-1:0];

        data_in = L_new_cel;

        active_board_read = !L_LD_cel_pg;
        active_board_write = L_LD_cel_pg;
    end
    else begin
        read_address_row = vga_row_idx;
        read_address_col = vga_col_idx;
        
        write_enable = input_write_value; // TODO: wanneer mag input schrijven?

        write_address_row = input_write_address_row;
        write_address_col = input_write_address_col;

        data_in = input_write_value;

        active_board_read = 1'b0;
        active_board_write = 1'b0;        
    end
end

register_board #(
    .row_count(row_count),
    .col_count(col_count)
) u_register_board (
    .clk(clk),
    .reset_n(reset_n),
    .data_in(data_in),
    .read_address_row(read_address_row),
    .read_address_col(read_address_col),
    .write_address_row(write_address_row),
    .write_address_col(write_address_col),
    .active_board_read(active_board_read),
    .active_board_write(active_board_write),
    .write_enable(write_enable),

    .data_out(data_out)
);

// nog interne wires
logic [row_bits-1:0] vga_row_idx;
logic [col_bits-1:0] vga_col_idx;
logic [row_bits+col_bits-1:0] cursorpos;

vga #(
    .NUM_ROWS(row_count),
    .NUM_COLS(col_count)
) u_vga (
    .clk(clk),
    .reset_n(reset_n),
    .ena(ena),
    .ui_in(ui_in),
    .uo_out(uo_out),
    .uio_in(uio_in),
    .uio_out(uio_out),
    .uio_oe(uio_oe),
    .simulation_running(simulation_running),
    .cursorpos(cursorpos),
    .cell_memory(data_out),
    .col_idx(vga_col_idx),
    .row_idx(vga_row_idx),
    .next_iter_allowed(next_iter_allowed)
);

endmodule
