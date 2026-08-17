`default_nettype none
`timescale 1ns / 1ps

/*
Algemene deel, deze module geschreven door Sieben
Dit is een controller voor het gehele project
*/

module project_controller (
    input logic clk,
    input logic reset_n,
    input logic next_iter,
    input logic L_idle,

    /* Nog niet geïmplementeerd
    input logic resume,
    input logic pause,
    input logic reset,
    */

    input logic start_stop_rise,

    output logic L_reset,
    output logic nic_reset,
    output logic reset_speed,
    output logic running,
    output logic next_iter_busy
);

  typedef enum logic [1:0] {
    START,
    DISPLAY,
    NEXT_ITER,
    PAUSE
  } state_e;

  state_e state;

  always_ff @(posedge clk or negedge reset_n) begin : next_state_logic
    if (!reset_n) begin
      state <= START;
    end else
      case (state)
        START: if (start_stop_rise) state <= DISPLAY;
        DISPLAY: begin
          if (start_stop_rise) begin
            state <= PAUSE;
          end else if (next_iter) begin
            state <= NEXT_ITER;
          end
        end
        NEXT_ITER: if (L_idle) state <= DISPLAY;
        PAUSE: begin
          if (start_stop_rise) state <= DISPLAY;
        end
        default: state <= START;
      endcase
  end

  always_comb begin : control_signals
    case (state)
      // default is voor START
      default:
      {L_reset, nic_reset, reset_speed, running, next_iter_busy} = {1'b1, 1'b1, 1'b1, 1'b0, 1'b0};
      DISPLAY:
      {L_reset, nic_reset, reset_speed, running, next_iter_busy} = {1'b0, 1'b0, 1'b0, 1'b1, 1'b0};
      NEXT_ITER:
      {L_reset, nic_reset, reset_speed, running, next_iter_busy} = {1'b0, 1'b0, 1'b0, 1'b1, 1'b1};
      PAUSE:
      {L_reset, nic_reset, reset_speed, running, next_iter_busy} = {1'b1, 1'b1, 1'b0, 1'b0, 1'b0};
    endcase
  end

endmodule
