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

module sim_speed (
    input logic clk,
    input logic reset_n,
    input logic reset,
    input logic increase,
    input logic decrease,

    output sim_speed_pkg::speed_e speed
);
    always_ff @( posedge clk or negedge reset_n ) begin
        if(!reset_n) begin
            speed <= sim_speed_pkg::QUARTER_HZ;
        end      
        else if(reset) begin
             speed <= sim_speed_pkg::QUARTER_HZ;
        end   
        else if(increase && speed != sim_speed_pkg::FOUR_HZ) begin
            speed <= sim_speed_pkg::speed_e'(speed + 3'd1);
        end
        else if(decrease && speed != sim_speed_pkg::QUARTER_HZ) begin
            speed <= sim_speed_pkg::speed_e'(speed - 3'd1);
        end            
    end
endmodule

`default_nettype wire