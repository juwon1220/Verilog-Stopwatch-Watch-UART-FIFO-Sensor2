`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/16 18:21:30
// Design Name: 
// Module Name: uart_tx
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


module uart_tx (
    input        clk,
    input        rst,
    input        start,
    input        b_tick,
    input  [7:0] tx_data, // parallel input
    output       tx,      // serial output
    output       tx_busy
);

    parameter [2:0] IDLE = 0, WAIT = 1, START = 2, DATA_TX = 3, STOP = 4;
    
    // state register
    reg [2:0] c_state, n_state;
    reg [2:0] c_db_cnt, n_db_cnt;
    reg [3:0] c_tick_cnt, n_tick_cnt;
    reg [7:0] c_data, n_data;
    reg c_tx, n_tx;
    reg c_busy, n_busy;

    // output
    assign tx = c_tx;
    assign tx_busy = c_busy;

    // sequential logic
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            c_state <= IDLE;
            c_tx <= 1'b1;
            c_busy <= 1'b0;
            c_db_cnt <= 0;
            c_tick_cnt <= 0;
            c_data <= 8'h00;
        end else begin
            c_state <= n_state;
            c_tx <= n_tx;
            c_busy <= n_busy;
            c_db_cnt <= n_db_cnt;
            c_tick_cnt <= n_tick_cnt;
            c_data <= n_data;
        end
    end

    // combinational logic
    always @(*) begin
        n_state = c_state;
        n_tx = c_tx;
        n_busy = c_busy;
        n_db_cnt = c_db_cnt;
        n_tick_cnt = c_tick_cnt;
        n_data = c_data;

        case (c_state)
            IDLE: begin
                n_tx = 1'b1;
                n_busy = 1'b0;
                n_tick_cnt = 4'h0;

                if(start == 1'b1) begin
                    n_busy = 1'b1; // mealy output
                    n_data = tx_data; // 비트 시프트를 위한 데이터 버퍼
                    n_state = WAIT;
                end
            end
            WAIT: begin
                //n_busy = 1'b1; // mealy output
                if(b_tick == 1'b1) n_state = START;
            end
            START: begin
                n_tx = 1'b0;
                n_db_cnt = 0;
                if(b_tick == 1'b1) begin
                    if (c_tick_cnt == 15) begin
                        n_tick_cnt = 4'h0;
                        n_state = DATA_TX;
                    end else begin
                        n_tick_cnt = c_tick_cnt + 1;
                    end
                end
            end
            DATA_TX: begin
                n_tx = c_data[0];  // LSB 방향으로 시프트하면서 0번째 비트를 출력해줌
                if(b_tick == 1'b1) begin
                    if (c_tick_cnt == 15) begin
                        n_data = c_data >> 1; // 버퍼에 입력된 신호를 시프트함
                        n_tick_cnt = 4'h0;
                        if (c_db_cnt == 7) begin
                            n_state = STOP;
                        end else begin
                            n_db_cnt = c_db_cnt + 1;
                            n_state = DATA_TX;
                        end
                    end else begin
                        n_tick_cnt = c_tick_cnt + 1;
                    end
                end
            end
            STOP: begin
                n_tx = 1'b1;
                if(b_tick == 1'b1) begin
                    if (c_tick_cnt == 15) begin
                        n_state = IDLE;
                    end else begin
                        n_tick_cnt = c_tick_cnt + 1;
                    end
                end 
            end
            default: n_state = c_state;
        endcase
    end
endmodule
