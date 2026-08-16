/*

Calculates the pixel color based on cell type (see vga_get_cell_type.sv) and if the pixel is in visible range.
If not in visible range, show black.

- cell_type: 2 bits
--> 00 dead, black 000000
--> 01 alive, white 111111
--> 10 cursor, blue 000011
--> 11 not assigned, invalid, red 110000

R, G en B zijn geregistreerd (1 klokcyclus vertraging). hsync en vsync komen
namelijk ook uit een register in vga_hvsync_generator.sv en lopen dus 1 cyclus
achter op hpos/vpos. Zonder dit register zou de kleur 1 pixel te vroeg op de
pinnen staan t.o.v. de sync-signalen, waardoor het beeld 1 pixel naar links
schuift en de eerste kolom 39 in plaats van 40 pixels breed is.

Created by Mathias Van Nuland

*/



`timescale 1ns / 1ps

module vga_get_pixel_color #(
    parameter int NUM_COLS = 16,
    parameter int NUM_ROWS = 12
) (
    input logic clk,
    input logic reset_n,
    input logic display_on,
    input logic [1:0] cell_type,
    output logic [1:0] R,
    output logic [1:0] G,
    output logic [1:0] B
);

  logic [1:0] R_next;
  logic [1:0] G_next;
  logic [1:0] B_next;

  always_comb begin
    if (display_on) begin
      case (cell_type)
        2'b00: begin  // dead
          R_next = 2'b00;
          G_next = 2'b00;
          B_next = 2'b00;
        end
        2'b01: begin  // alive
          R_next = 2'b11;
          G_next = 2'b11;
          B_next = 2'b11;
        end
        2'b10: begin  // cursor, blue
          R_next = 2'b00;
          G_next = 2'b00;
          B_next = 2'b11;
        end
        default: begin  // invalid --> red
          R_next = 2'b11;
          G_next = 2'b00;
          B_next = 2'b00;
        end

      endcase
    end else begin  // scanning position is not in visible range is not turned on, show black
      R_next = 0;
      G_next = 0;
      B_next = 0;
    end
  end

  // Uitlijnen met de geregistreerde hsync/vsync, zie commentaar bovenaan
  always_ff @(posedge clk) begin
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
