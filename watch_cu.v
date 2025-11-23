`timescale 1ns / 1ps

module watch_cu(
    input clk,
    input rst,
    input btn_clear,
    input btn_digit_move,
    input btn_inc,
    input btn_dec,
    input tx_empty,
    input [7:0] rx_data,
    output reg [3:0] state_led,
    output reg [1:0] digit_mode,
    output reg inc,              
    output reg dec,              
    output reg clear             
    );

    parameter IDLE = 2'b00,     // 기본 상태 (digit_mode = 00)
              ADJUST_SEC = 2'b01,   // 초 조정 모드 (digit_mode = 01)
              ADJUST_MIN = 2'b10,   // 분 조정 모드 (digit_mode = 10)
              ADJUST_HOUR = 2'b11;  // 시 조정 모드 (digit_mode = 11)

    reg [1:0] c_state, n_state;

    reg [3:0] n_state_led;
    reg n_inc, n_dec, n_clear;

    // state register
    always @(posedge clk, posedge rst) begin
        if(rst|((~tx_empty)&(rx_data == "S"))) begin
            c_state <= IDLE;
            digit_mode <= IDLE;
            inc <= 1'b0;
            dec <= 1'b0;
            clear <= 1'b0;
            state_led <= 4'b0000;
        end else begin
            c_state <= n_state;
            digit_mode <= n_state;
            inc <= n_inc;
            dec <= n_dec;
            clear <= n_clear;
            state_led <= n_state_led;
        end
    end

    // next state combinational logic
    always @(*) begin
        n_state = c_state;
        n_inc = 1'b0;
        n_dec = 1'b0;
        n_clear = 1'b0;
        n_state_led = state_led;
        // FSM 상태 전이 및 출력 제어
        case (c_state)
            IDLE: begin // 초기 상태
                n_state_led = 4'b0001;
                if ((btn_digit_move == 1'b1)|((~tx_empty)&(rx_data == "R"))) begin
                    n_state = ADJUST_SEC;
                    n_state_led = 4'b0010;
                end else if ((btn_clear == 1'b1)|((~tx_empty)&(rx_data == "L"))) begin
                    n_clear = 1'b1;
                end
            end
            ADJUST_SEC: begin // 초 조정 모드
                if ((btn_digit_move == 1'b1)|((~tx_empty)&(rx_data == "R"))) begin
                    n_state = ADJUST_MIN; // 분 조정 모드로 전환
                    n_state_led = 4'b0100;
                end else if ((btn_inc == 1'b1)|((~tx_empty)&(rx_data == "U"))) begin
                    n_inc = 1'b1;
                end else if ((btn_dec == 1'b1)|((~tx_empty)&(rx_data == "D"))) begin
                    n_dec = 1'b1;
                end else if ((btn_clear == 1'b1)|((~tx_empty)&(rx_data == "C"))) begin
                    n_clear = 1'b1;
                end
            end
            ADJUST_MIN: begin // 분 조정 모드
                if ((btn_digit_move == 1'b1)|((~tx_empty)&(rx_data == "R"))) begin
                    n_state = ADJUST_HOUR; // 시 조정 모드로 전환
                    n_state_led = 4'b1000;
                end else if ((btn_inc == 1'b1)|((~tx_empty)&(rx_data == "U"))) begin
                    n_inc = 1'b1;
                end else if ((btn_dec == 1'b1)|((~tx_empty)&(rx_data == "D"))) begin
                    n_dec = 1'b1;
                end else if ((btn_clear == 1'b1)|((~tx_empty)&(rx_data == "C"))) begin
                    n_clear = 1'b1;
                end
            end
            ADJUST_HOUR: begin // 시 조정 모드
                if ((btn_digit_move == 1'b1)|((~tx_empty)&(rx_data == "R"))) begin
                    n_state = IDLE; // 다시 초 조정 모드로 전환 (순환)
                    n_state_led = 4'b0001;
                end else if ((btn_inc == 1'b1)|((~tx_empty)&(rx_data == "U"))) begin
                    n_inc = 1'b1;
                end else if ((btn_dec == 1'b1)|((~tx_empty)&(rx_data == "D"))) begin
                    n_dec = 1'b1;
                end else if ((btn_clear == 1'b1)|((~tx_empty)&(rx_data == "C"))) begin
                    n_clear = 1'b1;
                end
            end
            default: begin
                n_state = IDLE; // latch 방지
            end
        endcase
    end
endmodule
