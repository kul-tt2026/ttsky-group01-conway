`timescale 1ns/1ps
module tb_Input ();
    reg clk,reset_n,button_down,button_left,button_right,button_set,button_start,button_up;
    wire [2:0] write_address_x,write_address_y;
    wire start,write_value;

    Input #(.DEBOUNCE_MAX(10)) invoer (
        .clk(clk),
        .reset_n(reset_n),
        .button_down(button_down),
        .button_left(button_left),
        .button_right(button_right),
        .button_set(button_set),
        .button_start(button_start),
        .button_up(button_up),
        .write_address_x(write_address_x),
        .write_address_y(write_address_y),
        .start(start),
        .write_value(write_value)
    );
    integer i;
    always begin
        #12.5 clk = ~clk;
    end
    initial begin
    $dumpfile("Input.vcd");
    $dumpvars(0, tb_Input);
    reset_n = 0;
    clk = 0;
    #100;
    reset_n = 1;
    #100;
    for(i=0;i<8;i=i+1) begin
        button_up = 1;
        button_left = 1;
        #300;
        button_up = 0;
        button_left = 0;
        #300;
    end

    button_right = 1;
    button_down = 1;
    button_set = 1;
    #300;
    button_right = 0;
    button_down = 0;
    button_set = 0;
    #300;
    button_start = 1;
    #300;
    button_start = 0;
    #300;

    $finish;
    end

endmodule