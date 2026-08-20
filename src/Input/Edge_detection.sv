`timescale 1ns/1ps
module Edge_detection (
    input clk,
    input reset_n,
    input button,
    output button_rise,
    output button_fall
);
reg rise;
reg fall;
reg prev_button;
always @(posedge clk or negedge reset_n) begin
    rise <= 0;
    fall <= 0;
    if (!reset_n) begin
        rise <= 0;
        fall <= 0;
        prev_button <=0;
    end
    else begin 
        if (button & ~prev_button) begin
            rise <= 1;
        end
        if (~button & prev_button) begin
            fall <= 1;
        end
        if (button != prev_button) begin
            prev_button <= button;
        end
    end
end
assign button_fall = fall;
assign button_rise = rise;

endmodule