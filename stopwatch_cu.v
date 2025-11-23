`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/08 13:24:46
// Design Name: 
// Module Name: fsm_controller
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


module stopwatch_cu(
    input clk,
    input rst,
    input btn_L,
    input btn_R,
    input tx_empty,
    input [7:0] rx_data,
    output run_stop,
    output clear
    );
 
    // parameter, state define
    parameter STOP = 3'b000, RUN = 3'b001, CLEAR = 3'b010;
    reg [2:0] c_state, // c_state = filp-flop type 
              n_state; // n_state = synthesized to feedback wire type { SL - wire(n_state) - CL } 
                       // c+n = total 3-bit flip-flop (not 6-bit)

    reg c_clear, n_clear; // 1-bit flip-flop

    // state register SL (updated every clock signal)
    always @(posedge clk, posedge rst) begin
        if(rst|(~tx_empty)&(rx_data == "S")) begin
            c_state <= STOP;
            c_clear <= 1'b0;
        end else begin
            c_state <= n_state;
            c_clear <= n_clear;
        end
    end

    // next state CL
    always @(*) begin
        n_state = c_state;
        n_clear = c_clear;
        case (c_state)
            STOP: begin
                n_clear = 1'b0;
                if ((btn_R == 1'b1)|((~tx_empty)&(rx_data == "R"))) begin
                    n_state = RUN;
                end else if ((btn_L == 1'b1)|((~tx_empty)&(rx_data == "L"))) begin
                    n_state = CLEAR;
                end else n_state = c_state;
            end
            RUN: begin
                if ((btn_R == 1'b1)|(~tx_empty)&(rx_data == "R")) begin
                    n_state = STOP;
                end else n_state = c_state;
            end
            CLEAR: begin
                n_state = STOP;
                n_clear = 1'b1;
            end
            default: n_state = c_state;
        endcase
    end

    // output CL
    assign run_stop = (c_state == RUN) ? 1'b1 : 1'b0;
    assign clear = c_clear;

endmodule
