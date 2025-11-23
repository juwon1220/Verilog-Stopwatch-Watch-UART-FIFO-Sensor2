`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/16 18:22:47
// Design Name: 
// Module Name: baud_tick_gen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module baud_tick_gen #(parameter BAUD = 9600)(
    input  clk,
    input  rst,
    output b_tick
);

    // tick bps : 9600
    localparam BAUD_CNT = 100_000_000 / (BAUD * 16);

    reg [$clog2(BAUD_CNT)-1:0] tick_cnt;
    reg r_tick;

    // assign output
    assign b_tick = r_tick;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            tick_cnt <= 0;
            r_tick <= 0;
        end else begin
            if(tick_cnt == BAUD_CNT - 1)begin
                tick_cnt <= 0;
                r_tick <= 1'b1;
            end else begin
                tick_cnt <= tick_cnt + 1;
                r_tick <= 0;
            end
        end
    end
endmodule