`timescale 1ns / 1ps

module vga_get_cell_type #(
    parameter int NUM_COLS = 16,
    parameter int NUM_ROWS = 12
) (
    input logic simulation_running,
    input logic [COL_BITS-1:0] col_idx,
    input logic [ROW_BITS-1:0] row_idx,
    input logic [COL_BITS+ROW_BITS-1:0] cursorpos,  // {col_idx,row_idx}
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
