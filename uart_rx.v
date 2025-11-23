`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/17 10:58:41
// Design Name: 
// Module Name: uart_rx
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


module uart_rx(
    input        clk,
    input        rst,
    input        b_tick,
    input        rx,
    output [7:0] rx_data,
    output       rx_busy,
    output       rx_done
    );

    // parameter & reg
    localparam [1:0] IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    reg [1:0] c_state, n_state;
    reg [3:0] c_b_tick_cnt, n_b_tick_cnt;
    reg [7:0] c_rx_data, n_rx_data;
    reg [2:0] c_bit_cnt, n_bit_cnt;
    reg c_rx_busy, n_rx_busy;
    reg c_rx_done, n_rx_done;

    // assign output
    assign rx_data = c_rx_data;
    assign rx_busy = c_rx_busy;
    assign rx_done = c_rx_done;

    // state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            c_b_tick_cnt <= 0;
            c_rx_data <= 8'h00;
            c_bit_cnt <= 0;
            c_rx_busy <= 0;
            c_rx_done <= 0;
        end else begin
            c_state <= n_state;
            c_b_tick_cnt <= n_b_tick_cnt;
            c_rx_data <= n_rx_data;
            c_bit_cnt <= n_bit_cnt;
            c_rx_busy <= n_rx_busy;
            c_rx_done <= n_rx_done;
        end
    end

    // next state combinational logic
    always @(*) begin
        n_state = c_state;
        n_b_tick_cnt = c_b_tick_cnt;
        n_rx_data = c_rx_data;
        n_bit_cnt = c_bit_cnt;
        n_rx_busy = c_rx_busy;
        n_rx_done = c_rx_done;

        case (c_state)
            IDLE: begin
                n_rx_done = 0; // done = 0
                if(!rx) begin // rx == 0, receive start
                    n_b_tick_cnt = 0; // initialize cnt value
                    n_bit_cnt = 0;
                    n_rx_busy = 1; // mealy output
                    n_state = START;
                end
            end
            START: begin
                if(b_tick == 1) begin
                    if (c_b_tick_cnt == 7) begin // tick_cnt == 7, DATA로 천이, 안정적으로 신호를 읽기 위함 (8 - 16 - 16 - 16 - ...)
                        n_b_tick_cnt = 0;
                        n_state = DATA;
                    end else begin
                        n_b_tick_cnt = c_b_tick_cnt + 1;
                    end
                end
            end
            DATA: begin
                if (b_tick == 1) begin
                    if (c_b_tick_cnt == 15) begin 
                        n_rx_data = {rx, c_rx_data[7:1]}; // MSB부터 비트 시프트를 통해 rx_data 출력
                        n_b_tick_cnt = 0;
                        if(c_bit_cnt == 7) begin
                            n_state = STOP;
                        end else begin
                            n_bit_cnt = c_bit_cnt + 1;
                        end
                    end else begin
                        n_b_tick_cnt = c_b_tick_cnt + 1;
                    end
                end
            end
            STOP: begin
                if (b_tick == 1) begin
                    if (c_b_tick_cnt == 15) begin
                        n_rx_busy = 0; // busy = 0
                        n_rx_done = 1; // done = 1
                        n_state = IDLE;
                    end else begin
                        n_b_tick_cnt = c_b_tick_cnt + 1;
                    end
                end
            end
        endcase
    end
endmodule
