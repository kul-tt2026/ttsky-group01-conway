`timescale 1ns / 1ps
module tb_Input ();
  localparam COLS = 16;
  localparam ROWS = 12;

  reg
      clk,
      reset_n,
      button_down,
      button_left,
      button_right,
      button_set,
      button_start_stop,
      button_up,
      button_cursor_on_off;

  wire [$clog2(COLS)-1:0] write_address_col;
  wire [$clog2(ROWS)-1:0] write_address_row;
  wire running, write_value, cursor_on;

  Input #(
      .DEBOUNCE_MAX(10),
      .COL_COUNT(COLS),
      .ROW_COUNT(ROWS)
  ) tb_invoer (
      .clk(clk),
      .reset_n(reset_n),
      .button_down(button_down),
      .button_left(button_left),
      .button_right(button_right),
      .button_set(button_set),
      .button_start_stop(button_start_stop),
      .button_up(button_up),
      .button_cursor_on_off(button_cursor_on_off),
      .write_address_col(write_address_col),
      .write_address_row(write_address_row),
      .running(running),
      .write_value(write_value),
      .cursor_on(cursor_on)
  );

  integer i;

  always begin
    #12.5 clk = ~clk;
  end

  // Press a button for one debounce-settle window, then release it,
  // matching the DEBOUNCE_MAX(10) setting on the DUT.
  task press_release(ref reg btn);
    begin
      btn = 1;
      #300;
      btn = 0;
      #300;
    end
  endtask

  initial begin
    $display("start");
    $dumpfile("Input.vcd");
    $dumpvars(0, tb_Input);

    reset_n = 0;
    clk = 0;
    button_up = 0;
    button_down = 0;
    button_left = 0;
    button_right = 0;
    button_set = 0;
    button_start_stop = 0;
    button_cursor_on_off = 0;
    #100;
    reset_n = 1;
    #100;

    // Move up+left repeatedly to test row/col wraparound at 0
    for (i = 0; i < ROWS + 1; i = i + 1) begin
      button_up   = 1;
      button_left = 1;
      #300;
      button_up   = 0;
      button_left = 0;
      #300;
    end

    // Move down+right, then write a cell
    button_right = 1;
    button_down  = 1;
    button_set   = 1;
    #300;
    button_right = 0;
    button_down  = 0;
    button_set   = 0;
    #300;

    // Toggle running on, verify it stays high without a second press
    button_start_stop = 1;
    #300;
    button_start_stop = 0;
    #300;
    if (running !== 1) $display("FAIL: running should be 1 after first start_stop press");

    // Toggle running off again
    button_start_stop = 1;
    #300;
    button_start_stop = 0;
    #300;
    if (running !== 0) $display("FAIL: running should be 0 after second start_stop press");

    // Toggle cursor_on off, then on again
    button_cursor_on_off = 1;
    #300;
    button_cursor_on_off = 0;
    #300;
    if (cursor_on !== 1) $display("FAIL: cursor_on should be 1 after first cursor_on_off press");

    button_cursor_on_off = 1;
    #300;
    button_cursor_on_off = 0;
    #300;
    if (cursor_on !== 0) $display("FAIL: cursor_on should be 0 after second cursor_on_off press");

    // Test right wraparound: move right past LAST_COL back to 0
    for (i = 0; i < COLS + 1; i = i + 1) begin
      button_right = 1;
      #300;
      button_right = 0;
      #300;
    end

    $display("done");
    $finish;
  end

endmodule
