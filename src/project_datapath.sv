`default_nettype none
`timescale 1ns / 1ps

module project_datapath #(
    parameter int row_count = 12,
    parameter int col_count = 16
) (
    input logic clk,
    input logic reset_n,
    input logic L_reset,
    input logic nic_reset,
    input logic reset_speed,
    input logic running,
    input logic next_iter_busy,

    input logic button_up,
    input logic button_down,
    input logic button_left,
    input logic button_right,
    input logic button_set,
    input logic button_start_stop,
    input logic button_cursor_on_off,
    input logic button_bounded_board,
    input logic button_speed_sim_up,
    input logic button_speed_sim_down,
    input logic button_reset,

    output logic [7:0] uo_out,  // Dedicated outputs
    input logic testing,

    output logic manual_reset,
    output logic start_stop_rise,
    output logic next_iter,
    output logic L_idle
);

  localparam int row_bits = $clog2(row_count);
  localparam int col_bits = $clog2(col_count);

  // Interne wires
  sim_speed_pkg::speed_e speed;
  logic reset_countdown, countdown_done;

  sim_speed u_sim_speed (
      .clk(clk),
      .reset_n(reset_n),
      .reset(reset_speed),
      .increase(speed_sim_increase),
      .decrease(speed_sim_decrease),

      .speed(speed)
  );

  assign reset_countdown = nic_reset || next_iter;

  next_iter_countdown u_next_iter_countdown (
      .clk(clk),
      .reset_n(reset_n),
      .testing(testing),
      .reset(reset_countdown),
      .speed(speed),

      .countdown_done(countdown_done)
  );

  // nog interne wires
  logic L_new_cel, L_write_enable, L_toggle_read, L_copying;
  logic bounded_board, speed_sim_decrease, speed_sim_increase;
  logic [row_bits - 1:0] L_row;
  logic [col_bits - 1:0] L_col;
  logic next_iter_allowed;
  logic data_in, active_board_read, active_board_write, toggle_read, write_enable, data_out;
  logic [row_bits-1:0] read_address_row, write_address_row, vga_row_idx;
  logic [col_bits-1:0] read_address_col, write_address_col, vga_col_idx;
  logic [row_bits+col_bits-1:0] cursorpos;
  logic [7:0] neighbour_out;
  mode_pkg::mode_e L_mode;
  
  assign next_iter = next_iter_allowed && countdown_done;

  always_comb begin
    if (bounded_board)  L_mode = mode_pkg::BOUNDED;
    else                L_mode = mode_pkg::TORUS;
  end

  // Latch input writes so they only get applied during vertical blanking
  // (next_iter_allowed), preventing the board from changing mid-scan.
  logic pending_write;
  logic [row_bits-1:0] pending_write_row;
  logic [col_bits-1:0] pending_write_col;
  logic pending_write_value;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      pending_write <= 1'b0;
      pending_write_row <= '0;
      pending_write_col <= '0;
      pending_write_value <= '0;
    end else if (input_write_value) begin
      pending_write       <= 1'b1;
      pending_write_row   <= input_write_address_row;
      pending_write_col   <= input_write_address_col;
      pending_write_value <= input_write_value;
    end else if (pending_write && next_iter_allowed && !next_iter_busy) begin
      pending_write <= 1'b0;  // applied, clear the pending flag
    end
  end

  L_main #(
      .row_count(row_count),
      .col_count(col_count)
  ) u_L_main (
      .clk(clk),
      .reset_n(reset_n),
      .L_reset(L_reset),
      .L_next_iter(next_iter),
      .L_mode(L_mode),
      .old_cel(data_out),
      .neighbours(neighbour_out),

      .L_idle(L_idle),
      .L_row(L_row),
      .L_col(L_col),
      .L_new_cel(L_new_cel),
      .L_write_enable(L_write_enable),
      .L_copying(L_copying),
      .L_toggle_read(L_toggle_read)
  );

  // meer interne wires
  logic [row_bits-1:0] input_write_address_row;
  logic [col_bits-1:0] input_write_address_col;
  logic input_write_value;
  logic cursor_on;

  Input #(
      .ROW_COUNT(row_count),
      .COL_COUNT(col_count),
      .DEBOUNCE_MAX(10)  // TODO testing only
  ) u_input (
      .clk(clk),
      .reset_n(reset_n),
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
      .button_reset(button_reset),
      .manual_reset(manual_reset),
      .running(running),

      .write_address_row(input_write_address_row),
      .write_address_col(input_write_address_col),
      .write_value(input_write_value),
      .start_stop_rise(start_stop_rise),
      .bounded_board(bounded_board),
      .speed_sim_down_rise(speed_sim_decrease),
      .speed_sim_up_rise(speed_sim_increase),
      .cursor_on(cursor_on)
  );

  assign cursorpos = {input_write_address_col, input_write_address_row};  // vga gebruikt {col, row}
  
  always_comb begin
    if (next_iter_busy) begin
      read_address_row = L_row;
      read_address_col = L_col;

      write_enable = L_write_enable;

      write_address_row = L_row;
      write_address_col = L_col;

      if (L_copying) data_in = data_out;
      else data_in = L_new_cel;

      active_board_read = !L_copying;
      active_board_write = L_copying;

      toggle_read = L_toggle_read;

    end else begin
      read_address_row = vga_row_idx;
      read_address_col = vga_col_idx;

      write_enable = pending_write && next_iter_allowed;

      write_address_row = pending_write_row;
      write_address_col = pending_write_col;

      data_in = pending_write_value;

      active_board_read = 1'b0;
      active_board_write = 1'b0;

      toggle_read = 1'b0;
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
      .toggle_read(toggle_read),
      .write_enable(write_enable),
      .neighbour_out(neighbour_out),
      .manual_reset(manual_reset),

      .data_out(data_out)
  );
  // Synchronize running and cursor_on to the display: only update these
  // copies during vertical blanking (next_iter_allowed), so VGA always sees
  // a single consistent value for the whole frame. Without this, a mid-frame
  // toggle can cause part of the screen to render with the old value and
  // part with the new value in the same frame (e.g. some dead cells grey,
  // others black; or the cursor overlay appearing on only part of the grid).
  logic running_display;
  logic cursor_on_display;
  logic [row_bits+col_bits-1:0] cursorpos_display;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      running_display   <= 1'b0;
      cursor_on_display <= 1'b0;
      cursorpos_display <= 0;
    end else if (next_iter_allowed) begin
      running_display   <= running;
      cursor_on_display <= cursor_on;
      cursorpos_display <= cursorpos;
    end
  end

  vga #(
      .NUM_ROWS(row_count),
      .NUM_COLS(col_count)
  ) u_vga (
      .clk(clk),
      .reset_n(reset_n),
      .uo_out(uo_out),
      .cursor_on(cursor_on_display),
      .running(running_display),
      .cursorpos(cursorpos_display),
      .cell_memory(data_out),
      .col_idx(vga_col_idx),
      .row_idx(vga_row_idx),
      .next_iter_allowed(next_iter_allowed)
  );

endmodule
