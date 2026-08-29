/*

Calculates the pixel color based on cell type and if the pixel is in visible range.
cell_type[1] = cursor on/off, cell_type[0] = cell alive/dead (per updated vga_get_cell_type.sv)

- cell_type: 2 bits
--> [1]=0, [0]=0: dead, no cursor       -> black/grey
--> [1]=0, [0]=1: alive, no cursor      -> white
--> [1]=1, [0]=0: dead, cursor present  -> diamond blue overlay on dead background
--> [1]=1, [0]=1: alive, cursor present -> diamond blue overlay on alive background

R, G, and B are registered (1 clock cycle delay). This is because hsync and vsync also come from a register in
vga_hvsync_generator.sv, and therefore lag 1 cycle behind hpos/vpos.
Without this register, the color would appear on the pins 1 pixel too early relative to the sync signals,
causing the image to shift 1 pixel to the left and making the first column 39 pixels wide instead of 40.

Created by Mathias Van Nuland

*/

`timescale 1ns / 1ps

module vga_get_pixel_color #(
    parameter int NUM_COLS = 16,
    parameter int NUM_ROWS = 12,
    parameter int CELL_SIZE = 40  // width/height of a single cell in pixels, matches icon dimensions
) (
    input logic clk,
    input logic reset_n,
    input logic display_on,
    input logic running,
    input logic [1:0] cell_type,
    input logic [$clog2(
CELL_SIZE
)-1:0] pixel_col_offset,  // col within current cell, 0..CELL_SIZE-1
    input logic [$clog2(
CELL_SIZE
)-1:0] pixel_row_offset,  // row within current cell, 0..CELL_SIZE-1

    output logic [1:0] R,
    output logic [1:0] G,
    output logic [1:0] B
);

  logic [1:0] R_next;
  logic [1:0] G_next;
  logic [1:0] B_next;

  logic cursor_on;
  logic cell_alive;
  logic icon_pixel;

  assign cursor_on  = cell_type[1];
  assign cell_alive = cell_type[0];

  // --------------- ICON FOR CURSOR --------------------

  logic [CELL_SIZE-1:0] icon[0:CELL_SIZE-1];
  initial begin
    icon[0]  = 40'b0000000000000000000110000000000000000000;
    icon[1]  = 40'b0000000000000000001111000000000000000000;
    icon[2]  = 40'b0000000000000000011111100000000000000000;
    icon[3]  = 40'b0000000000000000111111110000000000000000;
    icon[4]  = 40'b0000000000000001111111111000000000000000;
    icon[5]  = 40'b0000000000000011111111111100000000000000;
    icon[6]  = 40'b0000000000000111111111111110000000000000;
    icon[7]  = 40'b0000000000001111111111111111000000000000;
    icon[8]  = 40'b0000000000011111111111111111100000000000;
    icon[9]  = 40'b0000000000111111111111111111110000000000;
    icon[10] = 40'b0000000001111111111111111111111000000000;
    icon[11] = 40'b0000000011111111111111111111111100000000;
    icon[12] = 40'b0000000111111111111111111111111110000000;
    icon[13] = 40'b0000001111111111111111111111111111000000;
    icon[14] = 40'b0000011111111111111111111111111111100000;
    icon[15] = 40'b0000111111111111111111111111111111110000;
    icon[16] = 40'b0001111111111111111111111111111111111000;
    icon[17] = 40'b0011111111111111111111111111111111111100;
    icon[18] = 40'b0111111111111111111111111111111111111110;
    icon[19] = 40'b1111111111111111111111111111111111111111;
    icon[20] = 40'b1111111111111111111111111111111111111111;
    icon[21] = 40'b0111111111111111111111111111111111111110;
    icon[22] = 40'b0011111111111111111111111111111111111100;
    icon[23] = 40'b0001111111111111111111111111111111111000;
    icon[24] = 40'b0000111111111111111111111111111111110000;
    icon[25] = 40'b0000011111111111111111111111111111100000;
    icon[26] = 40'b0000001111111111111111111111111111000000;
    icon[27] = 40'b0000000111111111111111111111111110000000;
    icon[28] = 40'b0000000011111111111111111111111100000000;
    icon[29] = 40'b0000000001111111111111111111111000000000;
    icon[30] = 40'b0000000000111111111111111111110000000000;
    icon[31] = 40'b0000000000011111111111111111100000000000;
    icon[32] = 40'b0000000000001111111111111111000000000000;
    icon[33] = 40'b0000000000000111111111111110000000000000;
    icon[34] = 40'b0000000000000011111111111100000000000000;
    icon[35] = 40'b0000000000000001111111111000000000000000;
    icon[36] = 40'b0000000000000000111111110000000000000000;
    icon[37] = 40'b0000000000000000011111100000000000000000;
    icon[38] = 40'b0000000000000000001111000000000000000000;
    icon[39] = 40'b0000000000000000000110000000000000000000;
  end

  // icon[row] is MSB-first, so column 0 of the cell maps to bit (CELL_SIZE-1)
  assign icon_pixel = icon[pixel_row_offset][(CELL_SIZE-1)-int'(pixel_col_offset)];

  always_comb begin
    if (display_on) begin
      if (cursor_on && icon_pixel) begin
        // diamond overlay pixel -> blue, regardless of underlying cell state
        R_next = 2'b00;
        G_next = 2'b00;
        B_next = 2'b11;
      end else if (cell_alive) begin
        // alive, white
        R_next = 2'b11;
        G_next = 2'b11;
        B_next = 2'b11;
      end else begin
        // dead
        if (running) begin  // if running, black
          R_next = 2'b00;
          G_next = 2'b00;
          B_next = 2'b00;
        end else begin  // else, grey
          R_next = 2'b10;
          G_next = 2'b10;
          B_next = 2'b10;
        end
      end
    end else begin  // scanning position not in visible range, show black
      R_next = 0;
      G_next = 0;
      B_next = 0;
    end
  end

  // Make RGB sync to clock cycles, see comments above.
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      R <= 2'b00;
      G <= 2'b00;
      B <= 2'b00;
    end else begin
      R <= R_next;
      G <= G_next;
      B <= B_next;
    end
  end

endmodule
