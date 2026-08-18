`timescale 1ns/1ps
module Input #(parameter COL_COUNT = 8, parameter ROW_COUNT = 8 ,parameter DEBOUNCE_MAX = 19'd499999) (
    input clk,
    input reset_n,
    input button_up,
    input button_down,
    input button_left,
    input button_right,
    input button_set,
    input button_start,
    output reg [$clog2(COL_COUNT)-1:0] write_address_col,
    output reg [$clog2(ROW_COUNT)-1:0] write_address_row,
    output reg write_value,
    output reg start
);

wire clean_up;
wire clean_down;
wire clean_left;
wire clean_right;
wire clean_set;
wire clean_start;
wire up_rise;
wire down_rise;
wire left_rise;
wire right_rise;
wire set_rise;
wire start_rise;

localparam ROW_BITS = $clog2(ROW_COUNT);
localparam COL_BITS = $clog2(COL_COUNT);

localparam [ROW_BITS-1:0] LAST_ROW = ROW_BITS'(ROW_COUNT-1);
localparam [COL_BITS-1:0] LAST_COL = COL_BITS'(COL_COUNT-1);


Debouncer #(DEBOUNCE_MAX) up_D (
    .clk(clk),
    .reset_n(reset_n),
    .noisy_in(button_up),
    .clean_signal(clean_up)
);

Debouncer #(DEBOUNCE_MAX) down_D (
    .clk(clk),
    .reset_n(reset_n),
    .noisy_in(button_down),
    .clean_signal(clean_down)
);

Debouncer #(DEBOUNCE_MAX) left_D (
    .clk(clk),
    .reset_n(reset_n),
    .noisy_in(button_left),
    .clean_signal(clean_left)
);

Debouncer #(DEBOUNCE_MAX) right_D (
    .clk(clk),
    .reset_n(reset_n),
    .noisy_in(button_right),
    .clean_signal(clean_right)
);

Debouncer #(DEBOUNCE_MAX) set_D (
    .clk(clk),
    .reset_n(reset_n),
    .noisy_in(button_set),
    .clean_signal(clean_set)
);

Debouncer #(DEBOUNCE_MAX) start_D (
    .clk(clk),
    .reset_n(reset_n),
    .noisy_in(button_start),
    .clean_signal(clean_start)
);

Edge_detection up_E (
    .clk(clk),
    .reset_n(reset_n),
    .button(clean_up),
    .button_rise(up_rise),
    .button_fall()
);

Edge_detection down_E (
    .clk(clk),
    .reset_n(reset_n),
    .button(clean_down),
    .button_rise(down_rise),
    .button_fall()
);

Edge_detection left_E (
    .clk(clk),
    .reset_n(reset_n),
    .button(clean_left),
    .button_rise(left_rise),
    .button_fall()
);

Edge_detection right_E (
    .clk(clk),
    .reset_n(reset_n),
    .button(clean_right),
    .button_rise(right_rise),
    .button_fall()
);

Edge_detection set_E (
    .clk(clk),
    .reset_n(reset_n),
    .button(clean_set),
    .button_rise(set_rise),
    .button_fall()
);

Edge_detection start_E (
    .clk(clk),
    .reset_n(reset_n),
    .button(clean_start),
    .button_rise(start_rise),
    .button_fall()
);

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        write_address_col <= 0;
        write_address_row <= 0;
        write_value <= 0;
        start <= 0;
    end
    else begin
        write_value <= set_rise;
        start <= start_rise;
        if (up_rise) begin 
            if (write_address_row == 0) begin
                write_address_row <= LAST_ROW;
            end 
            else begin
                write_address_row <= write_address_row - 1;
            end
        end
        if (down_rise) begin 
            if (write_address_row == LAST_ROW) begin 
                write_address_row <= 0;
            end
            else begin
                write_address_row <= write_address_row + 1;
            end
        end
        if (right_rise) begin 
            if (write_address_col == LAST_COL) begin
                write_address_col <= 0;
            end
            else begin
                write_address_col <= write_address_col + 1;
            end
        end
        if (left_rise) begin 
            if (write_address_col == 0) begin
                write_address_col <= LAST_COL;
            end
            else begin
                write_address_col <= write_address_col - 1;
            end
        end
    end
end
endmodule