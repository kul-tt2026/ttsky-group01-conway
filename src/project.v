/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_conwaysgameoflife (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  parameter int M = 32;
  parameter int N = 16;
  
  reg [M-1:0][N-1:0] grid;


  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out[0] = grid[ui_in[4:0]][uio_in[3:0]];  // Example: ou_out is the sum of ui_in and uio_in
  assign uo_out[7:4] = {ui_in[7:5], 1'b0} + uio_in[7:4];
  assign uo_out[3:1] = 0;
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, rst_n, 1'b0};

  always @(posedge clk) begin
    if(ena)
      grid[ui_in[4:0]][uio_in[3:0]] <= !grid[ui_in[4:0]][uio_in[3:0]];
  end


endmodule
