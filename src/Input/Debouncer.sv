`timescale 1ns/1ps
module Debouncer #(parameter MAX = 18'd251750) (
    input clk,
    input reset_n,
    input noisy_in,
    output reg clean_signal
);

reg sync0, sync1;
always @(posedge clk or negedge reset_n) begin 
    if(!reset_n) begin
    sync0 <= 0;
    sync1 <= 0;
    end
    else begin 
    sync0 <= noisy_in;
    sync1 <= sync0;
    end
end 

reg [18:0] counter;

always @(posedge clk or negedge reset_n) begin 
    if(!reset_n) begin 
        counter <= 0;
        clean_signal <= 0;
    end 
    else begin
        if (sync1 != clean_signal) begin
            counter <= counter + 1;
            if (counter == MAX-1) begin
                clean_signal <= sync1;
            end
        end
        else begin 
            counter <= 0;
        end
    end
end 

endmodule