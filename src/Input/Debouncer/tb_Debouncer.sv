`timescale 1ns/1ps
module tb_Debouncer ();
reg clk,reset_n,noisy_in;
wire clean_signal;
Debouncer #(.MAX(10)) Debounce (
    .clk(clk),
    .reset_n(reset_n),
    .noisy_in(noisy_in),
    .clean_signal(clean_signal)
);
always begin
    #12.5 clk = ~clk;
end
initial begin
        $dumpfile("Debounce.vcd");
        $dumpvars(0, tb_Debounce);
        reset_n = 0;
        clk = 1;
        noisy_in = 0;
        #25;
        reset_n = 1;
        #25;
        noisy_in = 1;
        #75;
        noisy_in = 0;
        #50;
        noisy_in = 1;
        #300
        noisy_in = 0;
        #300;
        noisy_in = 1;
        #25;
        noisy_in = 0;
        #25;

        $finish;
end
endmodule