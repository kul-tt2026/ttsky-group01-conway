`timescale 1ns/1ps
module Input #(parameter BOARD_SIZE = 8, parameter DEBOUNCE_MAX = 19'd499999) (
    input clk,
    input reset_n,
    input button_up,
    input button_down,
    input button_left,
    input button_right,
    input button_set,
    input button_start,
    output reg [$clog2(BOARD_SIZE)-1:0] write_address_x,
    output reg [$clog2(BOARD_SIZE)-1:0] write_address_y,
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
        write_address_x <= 0;
        write_address_y <= 0;
        write_value <= 0;
    end
    else begin
        write_value <= set_rise;
        start <= start_rise;
        if (up_rise) begin 
            write_address_y <= write_address_y + 1;
        end
        if (down_rise) begin 
            write_address_y <= write_address_y - 1;
        end
        if (right_rise) begin 
            write_address_x <= write_address_x + 1;
        end
        if (left_rise) begin 
            write_address_x <= write_address_x - 1;
        end
    end
end

endmodule