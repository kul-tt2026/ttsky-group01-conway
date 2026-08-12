/*

Calculates the cell index position (col_idx and row_idx) based on pixel position (hpos and vpos). Depends on vga_hvsync_generator.sv
Parameters: number of columns and number of rows of the grid

Created by Mathias Van Nuland

*/

`timescale 1ns / 1ps

module vga_get_cell_idx #(
    parameter int NUM_COLS = 16,
    parameter int NUM_ROWS = 12
) (
    input logic [9:0] hpos,
    input logic [9:0] vpos,
    output logic [$clog2(NUM_COLS)-1:0] col_idx,
    output logic [$clog2(NUM_ROWS)-1:0] row_idx
);

  localparam int H_DISPLAY = 640;
  localparam int V_DISPLAY = 480;
  localparam int CELL_WIDTH = H_DISPLAY / NUM_COLS;
  localparam int CELL_HEIGHT = V_DISPLAY / NUM_ROWS;

  always_comb begin
    col_idx = $bits(col_idx)'(32'(hpos) / CELL_WIDTH);
    row_idx = $bits(row_idx)'(32'(vpos) / CELL_HEIGHT);
  end


endmodule
