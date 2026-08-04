`timescale 1ns/1ps
module tb_Edge_detection ();
    reg clk, reset_n, button;
    wire button_rise, button_fall;
        Edge_detection edge_detect (
            .clk(clk),
            .reset_n(reset_n),
            .button(button),
            .button_fall(button_fall),
            .button_rise(button_rise)
        );
    always begin
        #1 clk = ~clk;
    end
    initial begin
        $dumpfile("Edge_detector.vcd");
        $dumpvars(0, tb_Edge_detection);
        reset_n = 0;
        clk = 1;
        button = 0;
        #20;
        reset_n = 1;
        #200;
        button = 1;
        #200;
        button = 0;
        #200;

        $finish;
    end
endmodule