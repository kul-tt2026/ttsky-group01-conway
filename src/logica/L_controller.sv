`default_nettype none
`timescale 1ns/1ps

/*
Deel Logica, Sieben
Dit is de finite state machine
Moore, dus de outputs zijn enkel afhankelijk van de huidige state
*/

package mode_pkg;
    typedef enum logic {
        TORUS = 1'b0,
        BOUNDED = 1'b1 
    } mode_e;
endpackage

module L_controller (
    input logic clk,
    input logic reset_n,
    input logic reset_controller,
    input logic L_next_iter,
    input mode_pkg::mode_e L_mode,
    input logic address_max,
    input logic read_ready,

    output logic L_idle,
    output logic L_LD_cel_pg,
    output logic L_LD_cel_g,
    output logic advance_grid,
    output logic reset_address,
    output logic advance_sweep,
    output logic reset_sweep,
    output logic reset_decider,
    output mode_pkg::mode_e d_mode
);

typedef enum logic [2:0] {
    IDLE, COPY,
    READ_T, WRITE_T, MOVE_T,
    READ_B, WRITE_B, MOVE_B
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
        IDLE: if(L_next_iter) state <= COPY;
        COPY: if(address_max) begin
            if(L_mode === mode_pkg::TORUS) state <= READ_T;
            else state <= READ_B;                               // Idee is dat eens die een iteratie begonnen is met in bounded/torus, die die iteratie ook daarmee moet afmaken
        end
        READ_T: if(read_ready) state <= WRITE_T;
        WRITE_T: begin
            if (address_max) state <= IDLE;
            else state <= MOVE_T;
        end
        MOVE_T: state <= READ_T;
        READ_B: if(read_ready) state <= WRITE_B;
        WRITE_B: begin
            if (address_max) state <= IDLE;
            else state <= MOVE_B;
        end
        MOVE_B: state <= READ_B;
        default: state <= IDLE;
    endcase
end

always_comb begin : control_signals
    case (state)
        // default is voor IDLE
        default: {L_idle, L_LD_cel_pg, L_LD_cel_g, advance_grid, reset_address, advance_sweep, reset_sweep, reset_decider, d_mode} = 
                 {1'b1,   1'b0,        1'b0,       1'b0,         1'b1,          1'b0,          1'b1,        1'b1,          mode_pkg::TORUS};
        COPY:    {L_idle, L_LD_cel_pg, L_LD_cel_g, advance_grid, reset_address, advance_sweep, reset_sweep, reset_decider, d_mode} = 
                 {1'b0,   1'b1,        1'b0,       1'b1,         1'b0,          1'b0,          1'b1,        1'b1,          mode_pkg::TORUS};
        READ_T:  {L_idle, L_LD_cel_pg, L_LD_cel_g, advance_grid, reset_address, advance_sweep, reset_sweep, reset_decider, d_mode} = 
                 {1'b0,   1'b0,        1'b0,       1'b0,         1'b0,          1'b1,          1'b0,        1'b0,          mode_pkg::TORUS};
        WRITE_T: {L_idle, L_LD_cel_pg, L_LD_cel_g, advance_grid, reset_address, advance_sweep, reset_sweep, reset_decider, d_mode} = 
                 {1'b0,   1'b0,        1'b1,       1'b1,         1'b0,          1'b0,          1'b1,        1'b1,          mode_pkg::TORUS};
        MOVE_T:  {L_idle, L_LD_cel_pg, L_LD_cel_g, advance_grid, reset_address, advance_sweep, reset_sweep, reset_decider, d_mode} = 
                 {1'b0,   1'b0,        1'b0,       1'b0,         1'b0,          1'b1,          1'b0,        1'b0,          mode_pkg::TORUS};
        READ_B:  {L_idle, L_LD_cel_pg, L_LD_cel_g, advance_grid, reset_address, advance_sweep, reset_sweep, reset_decider, d_mode} = 
                 {1'b0,   1'b0,        1'b0,       1'b0,         1'b0,          1'b1,          1'b0,        1'b0,          mode_pkg::BOUNDED};
        WRITE_B: {L_idle, L_LD_cel_pg, L_LD_cel_g, advance_grid, reset_address, advance_sweep, reset_sweep, reset_decider, d_mode} = 
                 {1'b0,   1'b0,        1'b1,       1'b1,         1'b0,          1'b0,          1'b1,        1'b1,          mode_pkg::BOUNDED};
        MOVE_B:  {L_idle, L_LD_cel_pg, L_LD_cel_g, advance_grid, reset_address, advance_sweep, reset_sweep, reset_decider, d_mode} = 
                 {1'b0,   1'b0,        1'b0,       1'b0,         1'b0,          1'b1,          1'b0,        1'b0,          mode_pkg::BOUNDED};
    endcase
end
    
endmodule

`default_nettype wire
