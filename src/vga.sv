/*

Connects the vga modules together. See diagram for more details.

Created by Mathias Van Nuland

*/


module vga #(
    parameter int NUM_COLS = 16,
    parameter int NUM_ROWS = 12
) (
    output logic [7:0] uo_out,  // Dedicated outputs
    input  logic       clk,     // clock
    input  logic       reset_n, // reset_n - low to reset

    input logic cursor_on,
    input logic running,
    input logic [$clog2(NUM_COLS)+$clog2(NUM_ROWS)-1:0] cursorpos,
    input logic cell_memory,
    output logic [$clog2(NUM_COLS)-1:0] col_idx,
    output logic [$clog2(NUM_ROWS)-1:0] row_idx,
    output logic next_iter_allowed
);

  localparam int COL_BITS = $clog2(NUM_COLS);
  localparam int ROW_BITS = $clog2(NUM_ROWS);

  // VGA signals
  logic hsync;
  logic vsync;
  logic [1:0] R;
  logic [1:0] G;
  logic [1:0] B;
  logic display_on;
  logic [9:0] pix_x;
  logic [9:0] pix_y;
  logic [1:0] cell_type;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  vga_hvsync_generator um_vga_hvsync_generator (
      .clk(clk),
      .reset_n(reset_n),
      .hsync(hsync),
      .vsync(vsync),
      .display_on(display_on),
      .hpos(pix_x),
      .vpos(pix_y),
      .next_iter_allowed(next_iter_allowed)
  );

  vga_get_cell_idx #(
      .NUM_COLS(NUM_COLS),
      .NUM_ROWS(NUM_ROWS)
  ) um_vga_get_cell_idx (
      .hpos(pix_x),
      .vpos(pix_y),
      .display_on(display_on),
      .col_idx(col_idx),
      .row_idx(row_idx)
  );

  vga_get_cell_type #(
      .NUM_COLS(NUM_COLS),
      .NUM_ROWS(NUM_ROWS)
  ) um_vga_get_cell_type (
      .cursor_on(cursor_on),
      .col_idx(col_idx),
      .row_idx(row_idx),
      .cursorpos(cursorpos),
      .cell_memory(cell_memory),
      .cell_type(cell_type)
  );

  vga_get_pixel_color #(
      .NUM_COLS(NUM_COLS),
      .NUM_ROWS(NUM_ROWS)
  ) um_vga_get_pixel_color (
      .clk(clk),
      .reset_n(reset_n),
      .display_on(display_on),
      .cell_type(cell_type),
      .running(running),
      .R(R),
      .G(G),
      .B(B)
  );


endmodule
