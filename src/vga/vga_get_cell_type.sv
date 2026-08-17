/*

Calculates the cell type based on the cell index (see vga_get_cell_idx.sv)
inputs:
- simulation_running:   0 when user is editing the grid
                        1 when simulation is running and user cannot edit the grid
- col_idx and row_idx: column and row index of the cell in the grid -> see vga_get_cell_idx.sv
- cursorpos: position of the cursor on the screen. first bits is the column position, last bits are the row position
- cell_memory: value of the current cell in memory. 0 = dead, 1 = alive

output:
- cell_type: 2 bits
--> 00 dead
--> 01 alive
--> 10 cursor
--> 11 not assigned, invalid

Created by Mathias Van Nuland

*/


`timescale 1ns / 1ps

module vga_get_cell_type #(
    parameter int NUM_COLS = 16,
    parameter int NUM_ROWS = 12
) (
    input logic simulation_running,
    input logic [$clog2(NUM_COLS)-1:0] col_idx,
    input logic [$clog2(NUM_ROWS)-1:0] row_idx,
    input logic [$clog2(NUM_COLS)+$clog2(NUM_ROWS)-1:0] cursorpos,  // {col_idx,row_idx}
    input logic cell_memory,  // 0=dead,1=alive ; pulled from memory based on col_idx and row_idx
    output logic [1:0] cell_type
);
  localparam int COL_BITS = $clog2(NUM_COLS);
  localparam int ROW_BITS = $clog2(NUM_ROWS);

  always_comb begin
    if (!simulation_running && (cursorpos == {col_idx, row_idx})) begin
      cell_type = 2'b10;  // cursor
    end else begin
      cell_type = {1'b0, cell_memory};  // 00=dead, 01=alive
    end
  end

endmodule
