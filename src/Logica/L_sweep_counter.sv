`default_nettype none
`timescale 1ns/1ps

/*
Deel Logica, Sieben
Deze module houd een sweepcounter bij. We gaan per pixel alle acht 
omringende pixels moeten opvragen, deze counter houd bij waar we 
zitten in die 'sweep'. 
De conventie is: (wordt eigenlijk pas gebruikt in L_sweeper)
    8 1 2
    7 0 3
    6 5 4
De output read_ready wordt 1 als de sweep_counter hoger is dan acht.
Dit betekent dat alle omliggende pixels uitgelezen zijn.
*/

module L_sweep_counter (
    input logic clk,
    input logic reset_n,
    input logic advance_sweep,
    input logic reset_sweep,

    output logic [3:0] sweep_number,
    output logic read_ready
);

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sweep_number <= '0;
        end
        else if (reset_sweep) begin
            sweep_number <= '0;
        end
        else if (advance_sweep) begin
            sweep_number <= sweep_number + 1'b1;
        end

    end

    assign read_ready = (sweep_number > 4'd8);
 
endmodule

`default_nettype wire
