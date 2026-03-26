`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Douglas Nguyen
// 
// Create Date: 03/05/2026 09:07:24 PM
// Design Name: Sound_Effect_Board
// Module Name: button_debouncer
// Target Device: xc7a35tcpg236-1 (Basys3 Artix-7)
// 
// Description: Clean the physical signal of button, detect when it is pressed (rising edge)
//////////////////////////////////////////////////////////////////////////////////

module button_debouncer(
    input clk,
    input btn_noisy,
    
    output reg btn_pressed
);

// ===========================================
// Slow Sampling (~763 Hz)
// ===========================================

wire [17:0] clk_dv_inc;
reg [16:0] clk_dv;
reg clk_en;
reg clk_en_d;

assign clk_dv_inc = clk_dv + 1;

always @(posedge clk) begin
    clk_dv <= clk_dv_inc[16:0];
    clk_en <= clk_dv_inc[17];
    clk_en_d <= clk_en;
end

// ===========================================
// Debounce Shift Register & Input Sampling
// ===========================================

reg [2:0] btn_shift = 0;

always @(posedge clk) begin 
    if (clk_en)
        btn_shift <= {btn_noisy, btn_shift[2:1]};
end

// ===========================================
// Cleaned Rising Edge Detection (Output)
// ===========================================

always @(posedge clk) begin
    btn_pressed <= ~btn_shift[0] & btn_shift[1] & clk_en_d;
end

endmodule
