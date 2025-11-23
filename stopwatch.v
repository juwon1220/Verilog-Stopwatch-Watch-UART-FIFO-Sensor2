`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/09 16:02:33
// Design Name: 
// Module Name: stop_watch
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


module stopwatch(
    input clk,
    input rst,
    input sw,
    input btn_L, // clear
    input btn_R, // run, stop
    input tx_empty,
    input [7:0]rx_data,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output [7:0] stopwatch_data
);

    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;

    wire w_btn_L, w_btn_R;
    wire w_run_stop, w_clear;

    stop_watch_dp U_DP(
        .clk(clk),
        .rst(rst),
        .run_stop(w_run_stop),
        .clear(w_clear),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour)
    );

    fnd_controller_swt U_FND_CTRL(
        .clk(clk),
        .rst(rst),
        .sw(sw),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .time_data(stopwatch_data)
    );

    stopwatch_cu U_SW_CU(
        .clk(clk),
        .rst(rst),
        .btn_L(w_btn_L),
        .btn_R(w_btn_R),
        .tx_empty(tx_empty),
        .rx_data(rx_data),
        .run_stop(w_run_stop),
        .clear(w_clear)
    );

    btn_debouncer U_DBC_LEFT(
        .clk(clk),
        .rst(rst),
        .i_btn(btn_L),
        .o_btn(w_btn_L)
    );

    btn_debouncer U_DBC_RIGHT(
        .clk(clk),
        .rst(rst),
        .i_btn(btn_R),
        .o_btn(w_btn_R)
    );
endmodule

module stop_watch_dp (
    input clk,
    input rst,
    input run_stop,
    input clear,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_tick_100hz, w_tick_msec, w_tick_sec, w_tick_min;

    // to count hour tick
    tick_counter #(.TICK_CNT(24), .WIDTH(5)) U_HOUR(
        .clk(clk),
        .rst(rst),
        .run_stop(run_stop),
        .clear(clear),
        .i_tick(w_tick_min),
        .o_time(hour),
        .o_tick()
    );

    // to count min tick
    tick_counter #(.TICK_CNT(60), .WIDTH(6)) U_MIN(
        .clk(clk),
        .rst(rst),
        .run_stop(run_stop),
        .clear(clear),
        .i_tick(w_tick_sec),
        .o_time(min),
        .o_tick(w_tick_min)
    );

    // to count sec tick
    tick_counter #(.TICK_CNT(60), .WIDTH(6)) U_SEC(
        .clk(clk),
        .rst(rst),
        .run_stop(run_stop),
        .clear(clear),
        .i_tick(w_tick_msec),
        .o_time(sec),
        .o_tick(w_tick_sec)
    );

    // to count msec tick
    tick_counter #(.TICK_CNT(100), .WIDTH(7)) U_MSEC(
        .clk(clk),
        .rst(rst),
        .run_stop(run_stop),
        .clear(clear),
        .i_tick(w_tick_100hz),
        .o_time(msec),
        .o_tick(w_tick_msec)
    );

    // to generate 100hz tick signal
    tick_gen_100hz U_TICK_GEN(
        .clk(clk),
        .rst(rst),
        .run_stop(run_stop),
        .clear(clear),
        .o_tick(w_tick_100hz)
    );

endmodule

module tick_counter #(parameter TICK_CNT = 100, WIDTH = 7) (
    input clk,
    input rst,
    input run_stop,
    input clear,
    input i_tick,
    output [WIDTH-1:0] o_time,
    output o_tick
);

    reg [$clog2(TICK_CNT)-1:0] cnt_reg, cnt_next;
    reg tick_reg, tick_next;

    assign o_time = cnt_reg;
    assign o_tick = tick_reg;

    // shift register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            cnt_reg <= 0;
            tick_reg <= 0;
        end else begin
            if (!run_stop) begin // run_stop & clear
                if (clear) begin
                    cnt_reg <= 0;
                end else begin
                    cnt_reg <= cnt_reg;
                end
            end else begin
                    cnt_reg <= cnt_next;
                    tick_reg <= tick_next;
            end
        end
    end

    // next combinational logic
    always @(*) begin
        cnt_next = cnt_reg;
        tick_next = 1'b0; // initialize to 0 every system clk 
        // tick_next = tick_reg (hold value)

        if (i_tick) begin   // driving when i_tick is 1
           if (cnt_reg == TICK_CNT - 1) begin
            cnt_next = 0;
            tick_next = 1;
            end else begin
                cnt_next = cnt_reg + 1;
                tick_next = 0;
            end
        end
    end
endmodule

module tick_gen_100hz (
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
        if (rst) begin
            r_cnt <= 0;
            r_tick <= 0;
        end else begin
            if (!run_stop) begin // run_stop & clear
                if (clear) begin
                    r_cnt <= 0;
                end else begin
                    r_cnt <= r_cnt;
                end
            end else begin
                if(r_cnt == FCOUNT - 1) begin
                r_cnt <= 0;
                r_tick <= 1;
            end else begin
                r_cnt <= r_cnt + 1;
                r_tick <= 0;
            end
            end
        end
    end

    assign o_tick = r_tick;
endmodule
