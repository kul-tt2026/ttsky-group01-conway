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

    output logic L_idle,
    output logic L_write_enable,
    output logic L_copying,
    output logic L_toggle_read,
    output logic advance_grid,
    output logic reset_address,
    output mode_pkg::mode_e d_mode
);

typedef enum logic [1:0] {
    IDLE, COPY,
    BOUNDED, TORUS
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
            if(L_mode == mode_pkg::TORUS) state <= TORUS;
            else state <= BOUNDED;
        end
        BOUNDED: if(address_max) state <= IDLE;
        TORUS: if(address_max) state <= IDLE;
        default: state <= IDLE;
    endcase
end

always_comb begin : control_signals
    case (state)
        // default is voor IDLE
        default: {L_idle, L_write_enable, L_copying, L_toggle_read, advance_grid, reset_address, d_mode} = 
                 {1'b1,   1'b0,           1'b0,      1'b0,          1'b0,       1'b1,          mode_pkg::TORUS};
        COPY:    {L_idle, L_write_enable, L_copying, L_toggle_read, advance_grid, reset_address, d_mode} = 
                 {1'b0,   1'b1,           1'b1,      1'b0,          1'b1,       1'b0,          mode_pkg::TORUS};
        BOUNDED: {L_idle, L_write_enable, L_copying, L_toggle_read, advance_grid, reset_address, d_mode} = 
                 {1'b0,   1'b1,           1'b0,      1'b1,          1'b1,       1'b0,          mode_pkg::BOUNDED};
        TORUS:   {L_idle, L_write_enable, L_copying, L_toggle_read, advance_grid, reset_address, d_mode} = 
                 {1'b0,   1'b1,           1'b0,      1'b1,          1'b1,       1'b0,          mode_pkg::TORUS};
    endcase
end
    
endmodule

`default_nettype wire
