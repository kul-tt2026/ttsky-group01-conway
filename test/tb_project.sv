`default_nettype none
// ui_in = [up, down, left, right, set, start]
module tb_project ();
    logic clk, rst_n, ena;
    logic [7:0] ui_in, uio_in, uio_oe, uo_out, uio_out;
    tt_um_conwaysgameoflife u_conway (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_oe(uio_oe),
        .uio_out(uio_out),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    always begin
        #19.871 clk = ~clk;
    end
    initial begin
        ui_in = 0;
        rst_n = 0;
        ena = 1;
        clk = 1;
        #100;
        rst_n = 1;
        #100;
        ui_in[0] = 1;
        ui_in[3] = 1; // (1,1)
        #400;
        ui_in[0] = 0;
        ui_in[3] = 0;
        ui_in[4] = 1; // schrijven (1,1)
        #400;
        ui_in[4] = 0;
        ui_in[3] = 1; // (2,1)
        #400;
        ui_in[0] = 1;
        ui_in[3] = 1; // (3,2)
        #400;
        ui_in[0] = 0;
        ui_in[3] = 0;
        ui_in[4] = 1; // schrijven op (3,2)
        #400;
        ui_in[0] = 1;
        ui_in[3] = 1; 
        #400;
        ui_in[0] = 0;
        ui_in[3] = 0; // (4,3)
        #400;
        ui_in[0] = 1;
        ui_in[3] = 1; 
        #400;
        ui_in[0] = 0;
        ui_in[3] = 0; // (5,4)
        ui_in[2] = 1;
        #400;
        ui_in[2] = 0; // (5,3)
        ui_in[3] = 1; 
        #400;
        ui_in[3] = 0; // (6,3)
        ui_in[4] = 1; // schrijven op (6,3)
        #400;
        ui_in[5] = 1;
        ui_in[4] = 0;
        #400;
        ui_in[5] = 0; // start simulatie
        #400;


    end

endmodule