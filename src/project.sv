/*
 * Copyright (c) 2024 Mathias Van Nuland, Sander Vanlessen & Sieben De Witte
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_conwaysgameoflife #(
    parameter bit TESTING = 0   // If this is 1, the logic will update every frame (60Hz), which makes the project easier to test
) (
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

  parameter int ROWS = 12;
  parameter int COLS = 16;

  localparam int row_bits = $clog2(ROWS);
  localparam int col_bits = $clog2(COLS);

  // inputknoppen
  logic
      button_up,
      button_down,
      button_left,
      button_right,
      button_set,
      button_start_stop,
      testing,
      button_cursor_on_off;
  assign button_up = ui_in[0];
  assign button_down = ui_in[1];
  assign button_left = ui_in[2];
  assign button_right = ui_in[3];
  assign button_set = ui_in[4];
  assign button_start_stop = ui_in[5];
  assign button_cursor_on_off = ui_in[6];

  assign testing = ui_in[7]; // Als dit hoog is gaat logica elke frame updaten (zodat logica ook in de gate-level simulatie getest kan worden)

  // Intere wires
  logic
      next_iter, L_idle, L_reset, nic_reset, reset_speed, running, next_iter_busy, start_stop_rise;


  project_controller u_project_controller (
      .clk(clk),
      .reset_n(rst_n),
      .next_iter(next_iter),
      .L_idle(L_idle),
      .start_stop_rise(start_stop_rise),

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

      .uo_out (uo_out),
      .testing(testing),

      .start_stop_rise(start_stop_rise),
      .next_iter(next_iter),
      .L_idle(L_idle)
  );

endmodule
