/*
 * Copyright (c) 2024 Mathias Van Nuland, Sander Vanlessen & Sieben De Witte
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

  parameter int ROWS = 16;
  parameter int COLS = 16;
  
  localparam int row_bits = $clog2(ROWS);
  localparam int col_bits = $clog2(COLS);

  // interne connecties
  logic data_in, data_out, active_board_read, active_board_write, write_enable;
  logic [row_bits-1:0] address_row;  
  logic [col_bits-1:0] address_col;
  logic L_idle, L_reset, L_forward, cel_out_pg, L_new_cel, L_LD_cel_g, L_LD_cel_pg;
  logic [row_bits + col_bits - 1:0] L_address;
  
  assign L_forward = uio_in[5];
  assign uo_out[0] = data_out;
  assign uo_out[1] = L_idle;

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out[5:2] = 0;
  assign uo_out[7:6] = uio_in[7:6];
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, 1'b0};

  assign L_reset = '0;

  always_comb begin
    
    // Om van buitenaf het grid aan te passen
    if (!uio_in[0]) begin 
      address_row = ui_in[7:4];
      address_col = ui_in[3:0];

      write_enable = uio_in[1];
      active_board_write = uio_in[2];
      active_board_read = uio_in[3];
      data_in = uio_in[4];
    end
    // De simulatie runt zelf
    else begin           
      address_row = L_address[row_bits + col_bits - 1:col_bits];
      address_col = L_address[col_bits - 1:0];

      // Grids: 0 is grid, 1 is previous_grid
      if (L_LD_cel_pg) begin  // COPY MODE
        active_board_write = 1;
        active_board_read = 0;
        write_enable = 1;
        data_in = data_out;
      end 
      else if (L_LD_cel_g) begin
        active_board_write = 0;
        active_board_read = 1;
        write_enable = 1;
        data_in = L_new_cel;
      end
      else begin
        active_board_write = 0; // Don't care
        active_board_read = 1;
        write_enable = 0;
        data_in = 0; // Don't care
      end    
    end

    if (active_board_read == 1) cel_out_pg = data_out;
      else cel_out_pg = 0; // Don't care
    
  end

  register_board #(
    .row_count(ROWS),
    .col_count(COLS)
  ) u_register_board (
    .clk(clk),
    .reset_n(rst_n),
    .data_in(data_in),
    .active_board_read(active_board_read),
    .active_board_write(active_board_write),
    .write_enable(write_enable),
    .read_address_row(address_row),
    .read_address_col(address_col),
    .write_address_row(address_row),
    .write_address_col(address_col),
    .data_out(data_out)
  );

  L_main #(
    .row_count(ROWS),
    .col_count(COLS)
  ) u_L_main (
    .clk(clk),
    .reset_n(rst_n),
    .L_reset(L_reset),
    .L_forward(L_forward),
    .cel_out_pg(cel_out_pg),
    .L_idle(L_idle),
    .L_address(L_address),
    .L_new_cel(L_new_cel),
    .L_LD_cel_g(L_LD_cel_g),
    .L_LD_cel_pg(L_LD_cel_pg)
  );

endmodule
