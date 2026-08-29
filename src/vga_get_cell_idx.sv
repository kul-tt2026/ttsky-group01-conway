/*

Calculates the cell index position (col_idx and row_idx) based on pixel position (hpos and vpos). Depends on vga_hvsync_generator.sv
Parameters: number of columns and number of rows of the grid

Created by Mathias Van Nuland

*/

`timescale 1ns / 1ps

module vga_get_cell_idx #(
    parameter  int NUM_COLS    = 16,
    parameter  int NUM_ROWS    = 12,
    localparam int H_DISPLAY   = 640,
    localparam int V_DISPLAY   = 480,
    localparam int CELL_WIDTH  = H_DISPLAY / NUM_COLS,
    localparam int CELL_HEIGHT = V_DISPLAY / NUM_ROWS
) (
    input logic [9:0] hpos,
    input logic [9:0] vpos,
    input logic display_on,

    output logic [$clog2(NUM_COLS)-1:0] col_idx,
    output logic [$clog2(NUM_ROWS)-1:0] row_idx,
    output logic [$clog2(CELL_WIDTH)-1:0] pixel_col_offset,
    output logic [$clog2(CELL_HEIGHT)-1:0] pixel_row_offset
);

  initial begin
    if (NUM_COLS <= 0 || NUM_ROWS <= 0) $fatal("NUM_COLS and NUM_ROWS must be > 0");
  end

  always_comb begin
    if (display_on && (32'(hpos) < H_DISPLAY) && (32'(vpos) < V_DISPLAY)) begin // Make sure col_idx and row_idx never get out of bounds, failsafe for display_on
      col_idx = $bits(col_idx)'(32'(hpos) / CELL_WIDTH);
      row_idx = $bits(row_idx)'(32'(vpos) / CELL_HEIGHT);
      pixel_col_offset = $bits(pixel_col_offset)'(32'(hpos) % CELL_WIDTH);
      pixel_row_offset = $bits(pixel_row_offset)'(32'(vpos) % CELL_HEIGHT);
    end else begin
      col_idx = 0;
      row_idx = 0;
      pixel_col_offset = 0;
      pixel_row_offset = 0;
    end
  end


endmodule
