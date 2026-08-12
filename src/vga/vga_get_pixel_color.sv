/*

Calculates the pixel color based on cell type (see vga_get_cell_type.sv) and if the pixel is in visible range.
If not in visible range, show black.

- cell_type: 2 bits
--> 00 dead, black 000000
--> 01 alive, white 111111
--> 10 cursor, blue 000011
--> 11 not assigned, invalid, red 110000

Created by Mathias Van Nuland

*/



`timescale 1ns / 1ps

module vga_get_pixel_color #(
    parameter int NUM_COLS = 16,
    parameter int NUM_ROWS = 12
) (
    input logic display_on,
    input logic [1:0] cell_type,
    output logic [1:0] R,
    output logic [1:0] G,
    output logic [1:0] B
);

  always_comb begin
    if (display_on) begin
      case (cell_type)
        2'b00: begin  // dead
          R = 2'b00;
          G = 2'b00;
          B = 2'b00;
        end
        2'b01: begin  // alive
          R = 2'b11;
          G = 2'b11;
          B = 2'b11;
        end
        2'b10: begin  // cursor, blue
          R = 2'b00;
          G = 2'b00;
          B = 2'b11;
        end
        default: begin  // invalid --> red
          R = 2'b11;
          G = 2'b00;
          B = 2'b00;
        end

      endcase
    end else begin  // scanning position is not in visible range is not turned on, show black
      R = 0;
      G = 0;
      B = 0;
    end
  end


endmodule
