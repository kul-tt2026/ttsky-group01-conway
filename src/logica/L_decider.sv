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
    input logic reset_decider,
    input mode_pkg::mode_e d_mode,
    input logic row_max,
    input logic row_0,
    input logic col_max,
    input logic col_0,
    input logic [3:0] sweep_number, // In L_datapath is deze -1 gedaan, zodat die in sync is met de gelezen waarde

    output logic L_new_cel
);

    logic alive;
    logic [2:0] neighbours_count;

    always_ff @( posedge clk or negedge reset_n ) begin
        if (!reset_n) begin
            alive <= '0;
            neighbours_count <= '0;
        end
        else if (reset_decider) begin
            alive <= '0;
            neighbours_count <= '0;        
        end
        else if (sweep_number == 4'b0) begin
            alive <= cel;
        end
        else if (sweep_number < 4'd9) begin // de valid leeswaardes zijn tussen 0 en 8
            if(d_mode == mode_pkg::TORUS) begin
                neighbours_count <= neighbours_count + 3'(cel);
            end
            else begin // BOUNDED mode
            if(row_max && (sweep_number == 4'd4 || sweep_number == 4'd5 || sweep_number == 4'd6));
            else if(row_0 && (sweep_number == 4'd8 || sweep_number == 4'd1 || sweep_number == 4'd2));
            else if(col_max && (sweep_number == 4'd2 || sweep_number == 4'd3 || sweep_number == 4'd4));
            else if(col_0 && (sweep_number == 4'd6 || sweep_number == 4'd7 || sweep_number == 4'd8));
            else neighbours_count <= neighbours_count + 3'(cel);
                
            end
        end
    end

    always_comb begin
        if (alive) begin
            case (neighbours_count)
                3'd2: L_new_cel = 1'b1;
                3'd3: L_new_cel = 1'b1 ;
                default: L_new_cel = '0;
            endcase
        end
        else begin
            case (neighbours_count)
                3'd3: L_new_cel = 1'b1; 
                default: L_new_cel = '0;
            endcase
        end
    end

endmodule

`default_nettype wire
