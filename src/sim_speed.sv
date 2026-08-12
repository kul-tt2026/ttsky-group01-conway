`default_nettype none
`timescale 1ns/1ps

/*
Algemeen deel; deze module geschreven door Sieben
sim_speed houd de huidige simulatiesnelheid bij
*/

package sim_speed_pkg;
    typedef enum logic [2:0] {  // Als je extra snelheiden toevoegd: pas ook de max en min aan in de ifs meer naar beneden
        QUARTER_HZ = 3'b001,    // én voeg ze ook toe in next_iter_countdown!
        HALF_HZ    = 3'b010,    
        ONE_HZ     = 3'b011,
        TWO_HZ     = 3'b100,
        FOUR_HZ    = 3'b101
    } speed_e;
endpackage

import sim_speed_pkg::*;

module sim_speed (
    input logic clk,
    input logic reset_n,
    input logic reset,
    input logic increase,
    input logic decrease,

    output speed_e speed
);

    always_ff @( posedge clk or negedge reset_n ) begin
        if(!reset_n) begin
            speed <= QUARTER_HZ; // Beginsnelheid, kunnen we later nog vervangen
        end
        else if(reset) begin
            speed <= QUARTER_HZ; // Beginsnelheid, kunnen we later nog vervangen
        end
        else if(increase && speed != FOUR_HZ) begin
            speed <= speed.next();
        end
        else if(decrease && speed != QUARTER_HZ) begin
            speed <= speed.prev();
        end
    end
    
endmodule

`default_nettype wire