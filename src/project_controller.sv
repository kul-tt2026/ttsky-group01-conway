`default_nettype none
`timescale 1ns/1ps

/*
Algemene deel, deze module geschreven door Sieben
Dit is een controller voor het gehele project
*/

module project_controller (
    input logic clk,
    input logic reset_n,
    input logic start,
    input logic next_iter,
    input logic L_idle,

    /* Nog niet geïmplementeerd
    input logic resume,
    input logic pause,
    input logic reset,
    */

    output logic L_reset,
    output logic nic_reset,
    output logic reset_speed,
    output logic simulation_running,
    output logic next_iter_busy
);

    typedef enum logic [1:0] {
        START, DISPLAY, NEXT_ITER //, PAUSE (nog niet geïmplementeerd)
    } state_e;

    state_e state;

    always_ff @( posedge clk or negedge reset_n ) begin : next_state_logic
        if (!reset_n) begin
            state <= START;
        end
        else case (state)
            START: if(start) state <= DISPLAY;
            DISPLAY: if(next_iter) state <= NEXT_ITER;
            NEXT_ITER: if(L_idle) state <= DISPLAY;
            default: state <= START;
        endcase
    end

    always_comb begin : control_signals
        case (state)
            // default is voor START
            default:    {L_reset, nic_reset, reset_speed, simulation_running, next_iter_busy} = 
                        {1'b1,    1'b1,      1'b1,        1'b0,               1'b0};
            DISPLAY:    {L_reset, nic_reset, reset_speed, simulation_running, next_iter_busy} = 
                        {1'b0,    1'b0,      1'b0,        1'b1,               1'b0};
            NEXT_ITER:  {L_reset, nic_reset, reset_speed, simulation_running, next_iter_busy} = 
                        {1'b0,    1'b0,      1'b0,        1'b1,               1'b1};
        endcase
    end

endmodule
