`default_nettype none
`timescale 1ns/1ns

/*
Algemeen deel; deze module geschreven door Sieben
Deze module begint houd bij of er al genoeg tijd verstreken is om
een nieuwe iteratie van Logica te beginnen.
*/

import sim_speed_pkg::*; // Als de terminal hier errors over geeft: zorg dat sim_speed vóór deze module staat in de laadvolgorde


module next_iter_countdown #(
    parameter int clock_cycles_per_second = 25175000 // Hz,    accessible zodat het makkelijker te testen is
)(
    input logic clk,
    input logic reset_n,
    input logic reset,
    input speed_e speed,

    output logic countdown_done
);

    localparam int longest_clock_cycles_wait_time = 4*clock_cycles_per_second;  // Voor QUARTER_HZ
    localparam int counter_bits = $clog2(longest_clock_cycles_wait_time + 1); // zou 27 bits moeten zijn

    logic [counter_bits-1:0] count;

    always_ff @( posedge clk or negedge reset_n ) begin
        if(!reset_n) begin
            count <= '0; 
        end
        else if(reset) begin
            count <= '0; 
        end
        else if(count != '1) begin
            count <= count + 1;
        end
    end

    always_comb begin
        case (speed)
            QUARTER_HZ: countdown_done = (count >= (counter_bits)'(clock_cycles_per_second * 4) );
            HALF_HZ: countdown_done = (count >= (counter_bits)'(clock_cycles_per_second * 2) );
            ONE_HZ: countdown_done = (count >= (counter_bits)'(clock_cycles_per_second) );
            TWO_HZ: countdown_done = (count >= (counter_bits)'(clock_cycles_per_second / 2) );
            FOUR_HZ: countdown_done = (count >= (counter_bits)'(clock_cycles_per_second / 4) );
            default: countdown_done = (count >= (counter_bits)'(clock_cycles_per_second * 4) ); // QUARTER_HZ
        endcase
    end

endmodule

`default_nettype wire