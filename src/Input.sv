`timescale 1ns / 1ps
module Input #(
    parameter COL_COUNT = 8,
    parameter ROW_COUNT = 8,
    parameter DEBOUNCE_MAX = 18'd251750
) (
    input logic clk,
    input logic reset_n,
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
    input logic running,
    output logic [$clog2(COL_COUNT)-1:0] write_address_col,
    output logic [$clog2(ROW_COUNT)-1:0] write_address_row,
    output logic write_value,
    output logic start_stop_rise,
    output logic speed_sim_up_rise,
    output logic speed_sim_down_rise,
    output logic bounded_board,
    output logic manual_reset,
    output logic cursor_on
);

  logic clean_up;
  logic clean_down;
  logic clean_left;
  logic clean_right;
  logic clean_set;
  logic clean_start_stop;
  logic clean_cursor_on_off;
  logic clean_bounded_board;
  logic clean_speed_sim_up;
  logic clean_speed_sim_down;
  logic clean_reset;

  logic up_rise;
  logic down_rise;
  logic left_rise;
  logic right_rise;
  logic set_rise;
  logic cursor_on_off_rise;
  logic bounded_board_rise;
  logic reset_rise;

  localparam ROW_BITS = $clog2(ROW_COUNT);
  localparam COL_BITS = $clog2(COL_COUNT);

  localparam [ROW_BITS-1:0] LAST_ROW = ROW_BITS'(ROW_COUNT - 1);
  localparam [COL_BITS-1:0] LAST_COL = COL_BITS'(COL_COUNT - 1);


  Debouncer #(DEBOUNCE_MAX) up_D (
      .clk(clk),
      .reset_n(reset_n),
      .noisy_in(button_up),
      .clean_signal(clean_up)
  );

  Debouncer #(DEBOUNCE_MAX) down_D (
      .clk(clk),
      .reset_n(reset_n),
      .noisy_in(button_down),
      .clean_signal(clean_down)
  );

  Debouncer #(DEBOUNCE_MAX) left_D (
      .clk(clk),
      .reset_n(reset_n),
      .noisy_in(button_left),
      .clean_signal(clean_left)
  );

  Debouncer #(DEBOUNCE_MAX) right_D (
      .clk(clk),
      .reset_n(reset_n),
      .noisy_in(button_right),
      .clean_signal(clean_right)
  );

  Debouncer #(DEBOUNCE_MAX) set_D (
      .clk(clk),
      .reset_n(reset_n),
      .noisy_in(button_set),
      .clean_signal(clean_set)
  );

  Debouncer #(DEBOUNCE_MAX) start_stop_D (
      .clk(clk),
      .reset_n(reset_n),
      .noisy_in(button_start_stop),
      .clean_signal(clean_start_stop)
  );
  Debouncer #(DEBOUNCE_MAX) cursor_on_off_D (
      .clk(clk),
      .reset_n(reset_n),
      .noisy_in(button_cursor_on_off),
      .clean_signal(clean_cursor_on_off)
  );
  Debouncer #(DEBOUNCE_MAX) bounded_board_D (
      .clk(clk),
      .reset_n(reset_n),
      .noisy_in(button_bounded_board),
      .clean_signal(clean_bounded_board)
  );
  Debouncer #(DEBOUNCE_MAX) speed_sim_up_D (
      .clk(clk),
      .reset_n(reset_n),
      .noisy_in(button_speed_sim_up),
      .clean_signal(clean_speed_sim_up)
  );
  Debouncer #(DEBOUNCE_MAX) speed_sim_down_D (
      .clk(clk),
      .reset_n(reset_n),
      .noisy_in(button_speed_sim_down),
      .clean_signal(clean_speed_sim_down)
  );
  Debouncer #(DEBOUNCE_MAX) reset_n_D (
      .clk(clk),
      .reset_n(reset_n),
      .noisy_in(button_reset),
      .clean_signal(clean_reset)
  );

  Edge_detection up_E (
      .clk(clk),
      .reset_n(reset_n),
      .button(clean_up),
      .button_rise(up_rise),
      .button_fall()
  );

  Edge_detection down_E (
      .clk(clk),
      .reset_n(reset_n),
      .button(clean_down),
      .button_rise(down_rise),
      .button_fall()
  );

  Edge_detection left_E (
      .clk(clk),
      .reset_n(reset_n),
      .button(clean_left),
      .button_rise(left_rise),
      .button_fall()
  );

  Edge_detection right_E (
      .clk(clk),
      .reset_n(reset_n),
      .button(clean_right),
      .button_rise(right_rise),
      .button_fall()
  );

  Edge_detection set_E (
      .clk(clk),
      .reset_n(reset_n),
      .button(clean_set),
      .button_rise(set_rise),
      .button_fall()
  );

  Edge_detection start_E (
      .clk(clk),
      .reset_n(reset_n),
      .button(clean_start_stop),
      .button_rise(start_stop_rise),
      .button_fall()
  );

  Edge_detection cursor_on_off_E (
      .clk(clk),
      .reset_n(reset_n),
      .button(clean_cursor_on_off),
      .button_rise(cursor_on_off_rise),
      .button_fall()
  );
  Edge_detection bounded_board_E (
      .clk(clk),
      .reset_n(reset_n),
      .button(clean_bounded_board),
      .button_rise(bounded_board_rise),
      .button_fall()
  );
  Edge_detection speed_sim_up_E (
      .clk(clk),
      .reset_n(reset_n),
      .button(clean_speed_sim_up),
      .button_rise(speed_sim_up_rise),
      .button_fall()
  );
  Edge_detection speed_sim_down_E (
      .clk(clk),
      .reset_n(reset_n),
      .button(clean_speed_sim_down),
      .button_rise(speed_sim_down_rise),
      .button_fall()
  );
  Edge_detection reset_E (
      .clk(clk),
      .reset_n(reset_n),
      .button(clean_reset),
      .button_rise(reset_rise),
      .button_fall()
  );

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      write_address_col <= 0;
      write_address_row <= 0;
      write_value       <= 0;
      cursor_on         <= 0;
      bounded_board     <= 0;
      manual_reset      <= 1'b0;
    end else begin
      manual_reset <= reset_rise;

      if (cursor_on) begin
        write_value <= set_rise;
      end

      if (bounded_board_rise) begin
        bounded_board <= ~bounded_board;
      end

      if (running) begin  // Turn cursor off automatically when simulation is running
        cursor_on <= 0;
      end

      if (cursor_on_off_rise && !running) begin  // Only turn on cursor when simulation is paused
        cursor_on <= ~cursor_on;
      end

      if (up_rise) begin
        if (write_address_row == 0) begin
          write_address_row <= LAST_ROW;
        end else begin
          write_address_row <= write_address_row - 1;
        end
      end

      if (down_rise) begin
        if (write_address_row == LAST_ROW) begin
          write_address_row <= 0;
        end else begin
          write_address_row <= write_address_row + 1;
        end
      end

      if (right_rise) begin
        if (write_address_col == LAST_COL) begin
          write_address_col <= 0;
        end else begin
          write_address_col <= write_address_col + 1;
        end
      end

      if (left_rise) begin
        if (write_address_col == 0) begin
          write_address_col <= LAST_COL;
        end else begin
          write_address_col <= write_address_col - 1;
        end
      end
    end
  end
endmodule
