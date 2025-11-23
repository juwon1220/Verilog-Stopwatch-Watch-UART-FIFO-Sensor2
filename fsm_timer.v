`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/15 09:13:43
// Design Name: 
// Module Name: fsm_timer
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


module fsm_timer(
    input clk,
    input rst,
    input btn_L,
    input btn_R,
    input btn_U,
    input btn_D,
    input tx_empty,
    input [7:0]rx_data,
    output inc,
    output dec,
    output run_stop,
    output clear
    );
 
    // parameter, state define
    parameter STOP = 3'b000, RUN = 3'b001, CLEAR = 3'b010, INC = 3'b011, DEC = 3'b100;
    reg [2:0] c_state, // c_state = filp-flop type 
              n_state; // n_state = synthesized to feedback wire type { SL - wire(n_state) - CL } 
                       // c+n = total 3-bit flip-flop (not 6-bit)

    reg c_clear, n_clear; // 1-bit flip-flop
    reg c_inc, n_inc;
    reg c_dec, n_dec;

    // state register SL (updated every clock signal)
    always @(posedge clk, posedge rst) begin
        if(rst|((~tx_empty)&(rx_data == "S"))) begin
            c_state <= STOP;
            c_clear <= 1'b0;
            c_inc <= 1'b0;
            c_dec <= 1'b0;
        end else begin
            c_state <= n_state;
            c_clear <= n_clear;
            c_inc <= n_inc;
            c_dec <= n_dec;
        end
    end

    // next state CL
    always @(*) begin
        n_state = c_state;
        n_clear = c_clear;
        n_inc = c_inc;
        n_dec = c_dec;

        case (c_state)
            STOP: begin
                n_clear = 1'b0;
                n_inc = 1'b0;
                n_dec = 1'b0;
                
                if ((btn_R == 1'b1)|((~tx_empty)&(rx_data == "R"))) begin
                    n_state = RUN;
                end else if ((btn_L == 1'b1)|((~tx_empty)&(rx_data == "L"))) begin
                    n_state = CLEAR;
                end else if ((btn_U == 1'b1)|((~tx_empty)&(rx_data == "U"))) begin
                    n_state = INC;
                end else if ((btn_D == 1'b1)|(((~tx_empty)&(rx_data == "D")))) begin
                    n_state = DEC;
                end else n_state = c_state;
            end
            RUN: begin
                if ((btn_R == 1'b1)|((~tx_empty)&(rx_data == "R"))) begin
                    n_state = STOP;
                end else n_state = c_state;
            end
            CLEAR: begin
                n_state = STOP;
                n_clear = 1'b1;
            end
            INC: begin
                n_state = STOP;
                n_inc = 1'b1;
            end
            DEC: begin
                n_state = STOP;
                n_dec = 1'b1;
            end
            default: n_state = c_state;
        endcase
    end

    // output CL
    assign run_stop = (c_state == RUN) ? 1'b1 : 1'b0;
    assign clear = c_clear;
    assign inc = c_inc;
    assign dec = c_dec;

endmodule