`timescale 1ns / 1ps
`default_nettype none

module tb_vga_get_cell_idx_multi;

  localparam int H_DISPLAY = 640;
  localparam int V_DISPLAY = 480;

  localparam int NUM_COLS = 8;
  localparam int NUM_ROWS = 6;

  logic [9:0] hpos, vpos;
  logic [$clog2(NUM_COLS)-1:0] col_idx;
  logic [$clog2(NUM_ROWS)-1:0] row_idx;

  vga_get_cell_idx #(
      .NUM_COLS(NUM_COLS),
      .NUM_ROWS(NUM_ROWS)
  ) dut (
      .hpos   (hpos),
      .vpos   (vpos),
      .col_idx(col_idx),
      .row_idx(row_idx)
  );

  initial begin
    $dumpfile("tb_vga_get_cell_idx_multi.fst");
    $dumpvars(0, tb_vga_get_cell_idx_multi);
  end

endmodule
