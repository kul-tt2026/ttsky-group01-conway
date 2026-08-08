module invoer #(parameter BOARD_SIZE = 8) (
    input clk,
    input reset_n,
    input button_up,
    input button_down,
    input button_left,
    input button_right,
    input button_set,
    output reg [2:0] write_address_x,
    output reg [2:0] write_address_y,
    output reg write_value
);


always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        write_address_x <= 0;
        write_address_y <= 0;
        write_value <= 0;
    end
    else begin
        
    end
end

endmodule