module invoer #(parameter BOARD_SIZE = 8) (
    input clk,
    input reset_n,
    input button_up,
    input button_dow,
    input button_left,
    input button_right,
    input button_set,
    input button_write_enable,
    output [2:0] write_address_x,
    output [2:0] write_address_y,
    output write_value
);

reg [2:0] address_x;
reg [2:0] address_y;
reg value;

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin

    end
    
end

endmodule