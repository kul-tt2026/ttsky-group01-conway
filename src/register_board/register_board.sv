// input 
// reset_n == global reset
// data_in == pixel black or white (0 or 1)
// read_address == x and y coordinate for pixel that needs to be displayed
// write_address == x and y coordinate where new value gets saved
// write_enable == 1 if you want to write to a board
// active_board selcts which board is currently displayed (defined by logic)
// output 
// data_out == value of pixel from read address
// general: logic can write to a board, when its full active_board bitflips. The board thats just been written changes to read
// and the old read board can get new data written onto it.
// testing via cd src, cd register_board, make simulate in terminal 
`timescale 1ns/1ps
module register_board #(parameter BOARD_SIZE = 8) (
    input clk,
    input reset_n,
    input data_in,
    input [2:0] read_address_x,
    input [2:0] read_address_y,
    input [2:0] write_address_x,
    input [2:0] write_address_y,
    input active_board,
    input write_enable,
    output data_out
);

reg board0 [0:BOARD_SIZE-1][0:BOARD_SIZE-1];
reg board1 [0:BOARD_SIZE-1][0:BOARD_SIZE-1];

integer x;
integer y;

always @(posedge clk or negedge reset_n) begin 
    if (!reset_n) begin
        for (x=0; x<BOARD_SIZE; x++) begin
            for (y=0; y<BOARD_SIZE; y++) begin 
                board0[y][x] <= 1'b0;
                board1[y][x] <= 1'b0;
            end
        end
    end
    else begin
        if (write_enable) begin
            if (active_board) 
                board0[write_address_y][write_address_x] <= data_in;
            else
                board1[write_address_y][write_address_x] <= data_in;
        end
    end
end

assign data_out = active_board ? board1[read_address_y][read_address_x]:board0[read_address_y][read_address_x];

endmodule