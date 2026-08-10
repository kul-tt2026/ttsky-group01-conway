`default_nettype none
`timescale 1ns/1ps

/*
Deel Logica, Sieben
Dit is de finite state machine
Moore, dus de outputs zijn enkel afhankelijk van de huidige state
*/

module L_controller (
    input logic clk,
    input logic reset_n,
    input logic reset_controller,
    input logic L_forward,
    input logic address_max,
    input logic read_ready,

    output logic L_idle,
    output logic L_LD_cel_pg,
    output logic L_LD_cel_g,
    output logic advance_grid,
    output logic reset_address,
    output logic advance_sweep,
    output logic reset_sweep,
    output logic reset_decider
    // output logic d_mode = TORUS // nog niet geïmplementeerd
);

typedef enum logic [2:0] {
    IDLE, COPY,
    READ_T, WRITE_T, MOVE_T /*,
    READ_B, WRITE_B, MOVE_B */
} state_e;

state_e state;

always_ff @( posedge clk or negedge reset_n ) begin : next_state_logic
    if (!reset_n) begin
        state <= IDLE;
    end
    else if (reset_controller) begin
        state <= IDLE;
    end
    else case (state)
        IDLE: if(L_forward) state <= COPY;
        COPY: if(address_max) state <= READ_T;
        READ_T: if(read_ready) state <= WRITE_T;
        WRITE_T: begin
            if (address_max) state <= IDLE;
            else state <= MOVE_T;
        end
        MOVE_T: state <= READ_T;
        default: state <= IDLE;
    endcase
end

always_comb begin : control_signals
    case (state)
        // default is voor IDLE
        default: {L_idle, L_LD_cel_pg, L_LD_cel_g, advance_grid, reset_address, advance_sweep, reset_sweep, reset_decider} = 
                 {1'b1,   1'b0,        1'b0,       1'b0,         1'b1,          1'b0,          1'b1,        1'b1};
        COPY:    {L_idle, L_LD_cel_pg, L_LD_cel_g, advance_grid, reset_address, advance_sweep, reset_sweep, reset_decider} = 
                 {1'b0,   1'b1,        1'b0,       1'b1,         1'b0,          1'b0,          1'b1,        1'b1};
        READ_T:  {L_idle, L_LD_cel_pg, L_LD_cel_g, advance_grid, reset_address, advance_sweep, reset_sweep, reset_decider} = 
                 {1'b0,   1'b0,        1'b0,       1'b0,         1'b0,          1'b1,          1'b0,        1'b0};
        WRITE_T: {L_idle, L_LD_cel_pg, L_LD_cel_g, advance_grid, reset_address, advance_sweep, reset_sweep, reset_decider} = 
                 {1'b0,   1'b0,        1'b1,       1'b1,         1'b0,          1'b0,          1'b1,        1'b1};
        MOVE_T:  {L_idle, L_LD_cel_pg, L_LD_cel_g, advance_grid, reset_address, advance_sweep, reset_sweep, reset_decider} = 
                 {1'b0,   1'b0,        1'b0,       1'b0,         1'b0,          1'b1,          1'b0,        1'b1};
    endcase
end
    
endmodule

`default_nettype wire
