`default_nettype none
`timescale 1ns/1ps

/*
Deel Logica, Sieben
L_decider krijgt negen klokcycli lang een nieuwe cel te zien, volgens de conventie:
    8 1 2
    7 0 3
    6 5 4
Op de tiende klokcyclus krijgt die 'read_ready' binnen, en zal de beslissing voor
de nieuwe cel 0 die via 'L_new_cel' naar buiten gaat geïmplementeerd worden
*/

module L_decider (
    input logic clk,
    input logic reset_n,
    input logic cel,
    input logic [7:0] neighbours,
    input mode_pkg::mode_e d_mode,
    input logic row_max,
    input logic row_0,
    input logic col_max,
    input logic col_0,

    output logic L_new_cel
);

    logic [7:0] neighbour_mask, corrected_neighbours;
    logic [3:0] neighbours_count;

    always_comb begin

        neighbour_mask = '1;

        // bounded mode
        if (d_mode == mode_pkg::BOUNDED) begin

            if (row_0)      {neighbour_mask[0], neighbour_mask[1], neighbour_mask[7]} = '0; 
            if (row_max)    {neighbour_mask[3], neighbour_mask[4], neighbour_mask[5]} = '0; 
            if (col_0)      {neighbour_mask[5], neighbour_mask[6], neighbour_mask[7]} = '0; 
            if (col_max)    {neighbour_mask[1], neighbour_mask[2], neighbour_mask[3]} = '0; 
            
        end
        corrected_neighbours = neighbours & neighbour_mask;
        neighbours_count = $countones(corrected_neighbours);

        if (cel) begin  // cel zelf leeft
            case (neighbours_count)
                4'd2: L_new_cel = 1'b1;
                4'd3: L_new_cel = 1'b1 ;
                default: L_new_cel = '0;
            endcase
        end
        else begin  // cel zelf is dood
            case (neighbours_count)
                4'd3: L_new_cel = 1'b1; 
                default: L_new_cel = '0;
            endcase
        end
    end

endmodule

`default_nettype wire
