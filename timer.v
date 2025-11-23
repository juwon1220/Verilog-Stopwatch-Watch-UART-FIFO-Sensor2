`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/15 09:11:20
// Design Name: 
// Module Name: timer
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


module timer(
    input clk,
    input rst,
    input sw,
    input btn_L, // clear
    input btn_R, // digit_move
    input btn_U, // increase
    input btn_D, // decrease
    input tx_empty,
    input [7:0] rx_data,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output timer_led,
    output [7:0] timer_data
    );

    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;

    wire w_btn_L, w_btn_R, w_btn_inc, w_btn_dec;
    wire w_inc, w_dec, w_clear, w_run_stop;

    btn_debouncer U_DBC_CLEAR(
        .clk(clk),
        .rst(rst),
        .i_btn(btn_L),
        .o_btn(w_btn_L)
    );

    btn_debouncer U_DBC_RS(
        .clk(clk),
        .rst(rst),
        .i_btn(btn_R),
        .o_btn(w_btn_R)
    );

    btn_debouncer U_DBC_INCREASE(
        .clk(clk),
        .rst(rst),
        .i_btn(btn_U),
        .o_btn(w_btn_inc)
    );

    btn_debouncer U_DBC_DECREASE(
        .clk(clk),
        .rst(rst),
        .i_btn(btn_D),
        .o_btn(w_btn_dec)
    );

    fsm_timer U_FSM_TIMER(
        .clk(clk),
        .rst(rst),
        .btn_L(w_btn_L),
        .btn_R(w_btn_R),
        .btn_U(w_btn_inc),
        .btn_D(w_btn_dec),
        .tx_empty(tx_empty),
        .rx_data(rx_data),
        .inc(w_inc),
        .dec(w_dec),
        .run_stop(w_run_stop),
        .clear(w_clear)
    );

    timer_dp U_DP_T(
        .clk(clk),
        .rst(rst),
        .inc(w_inc),
        .dec(w_dec),
        .run_stop(w_run_stop),
        .clear(w_clear),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour),
        .timer_led(timer_led)
    );

    fnd_controller_swt U_FND_CTRL_TIMER(
        .clk(clk),
        .rst(rst),
        .sw(sw),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .time_data(timer_data)
    );
endmodule

module timer_dp (
    input clk,
    input rst,
    input inc,
    input dec,
    input run_stop,
    input clear,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour,
    output timer_led
);
    wire timer_stop_flag;
    wire w_tick_100hz, w_tick_msec, w_tick_sec, w_tick_min;

    assign timer_led = (~timer_stop_flag)&(run_stop);
    assign timer_stop_flag = ((hour==0)&(min==0)&(sec==0)&(msec==0))? 0 : 1;

    //assign run_stop = ((hour==0)&(min==0)&(sec==0))? 0 : 1;


    // to count hour tick
    tick_counter_t #(.TICK_CNT(24), .WIDTH(5), .VALUE(0)) U_HOUR_W(
        .clk(clk),
        .rst(rst),
        .inc(),
        .dec(),
        .run_stop(run_stop & timer_stop_flag),
        .clear(clear),
        .i_tick(w_tick_min),
        .o_time(hour),
        .o_tick()
    );

    // to count min tick
    tick_counter_t #(.TICK_CNT(60), .WIDTH(6), .VALUE(1)) U_MIN_W(
        .clk(clk),
        .rst(rst),
        .inc(inc),
        .dec(dec),
        .run_stop(run_stop & timer_stop_flag),
        .clear(clear),
        .i_tick(w_tick_sec),
        .o_time(min),
        .o_tick(w_tick_min)
    );

    // to count sec tick
    tick_counter_t #(.TICK_CNT(60), .WIDTH(6)) U_SEC_W(
        .clk(clk),
        .rst(rst),
        .inc(),
        .dec(),
        .run_stop(run_stop & timer_stop_flag),
        .clear(clear),
        .i_tick(w_tick_msec),
        .o_time(sec),
        .o_tick(w_tick_sec)
    );

    // to count msec tick
    tick_counter_t #(.TICK_CNT(100), .WIDTH(7)) U_MSEC_W(
        .clk(clk),
        .rst(rst),
        .inc(),
        .dec(),
        .run_stop(run_stop & timer_stop_flag),
        .clear(clear),
        .i_tick(w_tick_100hz),
        .o_time(msec),
        .o_tick(w_tick_msec)
    );

    // to generate 100hz tick signal
    tick_gen_100hz_t U_TICK_GEN_W(
        .clk(clk),
        .rst(rst),
        .run_stop(run_stop & timer_stop_flag),
        .clear(clear),
        .o_tick(w_tick_100hz)
    );

endmodule

module tick_counter_t #(parameter TICK_CNT = 100, WIDTH = 7, VALUE = 0) (
    input clk,
    input rst,
    input inc,
    input dec,
    input run_stop,
    input clear,
    input i_tick,
    output [WIDTH-1:0] o_time,
    output o_tick
);

    reg [$clog2(TICK_CNT)-1:0] r_cnt, n_cnt;
    reg r_tick, n_tick;

    assign o_time = r_cnt;
    assign o_tick = r_tick;

    // shift register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_cnt <= VALUE;
            r_tick <= 0;
        end else begin
                r_cnt <= n_cnt;
                r_tick <= n_tick;
        end
    end

    // next combinational logic
    always @(*) begin
        n_cnt  = r_cnt;
        n_tick = 1'b0;

        if (i_tick && run_stop) begin
            if (r_cnt == 0) begin
                n_cnt  = TICK_CNT - 1;
                n_tick = 1;
            end else begin
                n_cnt  = r_cnt - 1;
                n_tick = 0;
            end
        end

        if (clear) begin
            n_cnt = VALUE;
        end else if (inc) begin
            if (r_cnt >= TICK_CNT - 1) begin
                n_cnt = 0;
            end else begin
                n_cnt = r_cnt + 1;
            end
        end else if (dec) begin
            if (r_cnt == 0) begin
                n_cnt = TICK_CNT - 1;
            end else begin
                n_cnt = r_cnt - 1;
            end
        end
    end

    assign o_time = r_cnt;
    assign o_tick = r_tick;
endmodule

module tick_gen_100hz_t (
    input clk,
    input rst,
    input run_stop,
    input clear,
    output o_tick
);

    parameter FCOUNT = 1_000_000;
    reg [$clog2(FCOUNT)-1:0] r_cnt;
    reg r_tick;

    always @(posedge clk, posedge rst) begin
        if (rst || clear) begin
            r_cnt <= 0;
            r_tick <= 0;
        end else if(run_stop) begin
                if(r_cnt == FCOUNT - 1) begin
                    r_cnt <= 0;
                    r_tick <= 1;
                end else begin
                    r_cnt <= r_cnt + 1;
                    r_tick <= 0;
                end
        end else r_cnt <= r_cnt;
    end

    assign o_tick = r_tick;
endmodule