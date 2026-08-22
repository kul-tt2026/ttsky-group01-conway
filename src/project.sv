/*
 * Copyright (c) 2024 Mathias Van Nuland, Sander Vanlessen & Sieben De Witte
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_conwaysgameoflife (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Unused
  assign uio_out = 0;
  assign uio_oe  = 0;

  localparam int ROWS = 12;
  localparam int COLS = 16;

  // inputknoppen
  logic
      button_up,
      button_down,
      button_left,
      button_right,
      button_set,
      button_start_stop,
      testing_n,
      testing,
      button_cursor_on_off,
      button_speed_sim_up,
      button_speed_sim_down,
      button_bounded_board,
      button_reset_n;

  assign button_up = ui_in[0];
  assign button_down = ui_in[1];
  assign button_left = ui_in[2];
  assign button_right = ui_in[3];
  assign button_set = ui_in[4];
  assign button_start_stop = ui_in[5];
  assign button_cursor_on_off = ui_in[6];
  assign button_bounded_board = ui_in[7];
  assign button_speed_sim_up = uio_in[0];
  assign button_speed_sim_down = uio_in[1];
  assign button_reset_n = uio_in[2];
  assign testing_n = uio_in[7]; // Als dit laag is gaat logica elke frame updaten (zodat logica ook in de gate-level simulatie getest kan worden)
                                // reset en testing actief laag, dit verminderd het risico op accidentele activaties
  assign testing = !testing_n;

  // Intere wires
  logic next_iter, L_idle, L_reset, nic_reset, reset_speed, running, next_iter_busy, start_stop_rise, manual_reset;


  project_controller u_project_controller (
      .clk(clk),
      .reset_n(rst_n),
      .next_iter(next_iter),
      .L_idle(L_idle),
      .start_stop_rise(start_stop_rise),
      .manual_reset(manual_reset),

      .L_reset(L_reset),
      .nic_reset(nic_reset),
      .reset_speed(reset_speed),
      .running(running),
      .next_iter_busy(next_iter_busy)
  );

  project_datapath #(
      .row_count(ROWS),
      .col_count(COLS)
  ) u_project_datapath (
      .clk(clk),
      .reset_n(rst_n),
      .L_reset(L_reset),
      .nic_reset(nic_reset),
      .reset_speed(reset_speed),
      .running(running),
      .next_iter_busy(next_iter_busy),

      .button_up(button_up),
      .button_down(button_down),
      .button_left(button_left),
      .button_right(button_right),
      .button_set(button_set),
      .button_start_stop(button_start_stop),
      .button_cursor_on_off(button_cursor_on_off),
      .button_bounded_board(button_bounded_board),
      .button_speed_sim_up(button_speed_sim_up),
      .button_speed_sim_down(button_speed_sim_down),
      .button_reset(!button_reset_n), // Input werkt met een active high versie, dus een ! voor de active low

      .uo_out (uo_out),
      .testing(testing),

      .manual_reset(manual_reset),
      .start_stop_rise(start_stop_rise),
      .next_iter(next_iter),
      .L_idle(L_idle)
  );

endmodule
