`timescale 1ns / 1ps

module watch(
    input clk,
    input rst,
    input sw,
    input btn_L, // clear
    input btn_R, // digit_move
    input btn_U, // increase
    input btn_D, // decrease
    input tx_empty,
    input [7:0] rx_data,
    output [3:0] state_led,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output [7:0] watch_data
);

    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;

    wire [1:0]w_digit_mode;

    wire w_btn_L, w_btn_R, w_btn_inc, w_btn_dec;
    wire w_inc, w_dec, w_clear;

    btn_debouncer U_DBC_CLEAR(
        .clk(clk),
        .rst(rst),
        .i_btn(btn_L),
        .o_btn(w_btn_L)
    );

    btn_debouncer U_DBC_DIGIT_MOVE(
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

    watch_cu U_WATCH_CU(
        .clk(clk),
        .rst(rst),
        .btn_clear(w_btn_L),
        .btn_digit_move(w_btn_R),
        .btn_inc(w_btn_inc),
        .btn_dec(w_btn_dec),
        .tx_empty(tx_empty),
        .rx_data(rx_data),
        .state_led(state_led),
        .digit_mode(w_digit_mode),
        .inc(w_inc),
        .dec(w_dec),
        .clear(w_clear)
    );

    watch_dp U_DP_W(
        .clk(clk),
        .rst(rst),
        .digit_mode(w_digit_mode),
        .inc(w_inc),
        .dec(w_dec),
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
        .time_data(watch_data)
    );

endmodule

module watch_dp (
    input clk,
    input rst,
    input [1:0]digit_mode,
    input inc,
    input dec,
    input clear,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_tick_100hz, w_tick_msec, w_tick_sec, w_tick_min;

    wire [1:0] hour_mode;
    wire [1:0] min_mode;
    wire [1:0] sec_mode;
    wire [1:0] msec_mode;
    
    assign hour_mode = (clear == 1'b1) ? 2'b11 : (digit_mode == 2'b011) ? (inc ? 2'b01 : (dec ? 2'b10 : 2'b00)) : 2'b00;
    assign min_mode  = (clear == 1'b1) ? 2'b11 : (digit_mode == 2'b010) ? (inc ? 2'b01 : (dec ? 2'b10 : 2'b00)) : 2'b00;
    assign sec_mode  = (clear == 1'b1) ? 2'b11 : (digit_mode == 2'b001) ? (inc ? 2'b01 : (dec ? 2'b10 : 2'b00)) : 2'b00;
    assign msec_mode = (clear == 1'b1) ? 2'b11 : 2'b00;

    // to count hour tick
    tick_counter_w #(.TICK_CNT(24), .WIDTH(5), .VALUE(12)) U_HOUR_W(
        .clk(clk),
        .rst(rst),
        .mod(hour_mode),
        .i_tick(w_tick_min),
        .o_time(hour),
        .o_tick()
    );

    // to count min tick
    tick_counter_w #(.TICK_CNT(60), .WIDTH(6)) U_MIN_W(
        .clk(clk),
        .rst(rst),
        .mod(min_mode),
        .i_tick(w_tick_sec),
        .o_time(min),
        .o_tick(w_tick_min)
    );

    // to count sec tick
    tick_counter_w #(.TICK_CNT(60), .WIDTH(6)) U_SEC_W(
        .clk(clk),
        .rst(rst),
        .mod(sec_mode),
        .i_tick(w_tick_msec),
        .o_time(sec),
        .o_tick(w_tick_sec)
    );

    // to count msec tick
    tick_counter_w #(.TICK_CNT(100), .WIDTH(7)) U_MSEC_W(
        .clk(clk),
        .rst(rst),
        .mod(msec_mode),
        .i_tick(w_tick_100hz),
        .o_time(msec),
        .o_tick(w_tick_msec)
    );

    // to generate 100hz tick signal
    tick_gen_100hz_w U_TICK_GEN_W(
        .clk(clk),
        .rst(rst),
        .o_tick(w_tick_100hz)
    );

endmodule

module tick_counter_w #(parameter TICK_CNT = 100, WIDTH = 7, VALUE = 0) (
    input clk,
    input rst,
    input [1:0] mod,
    input i_tick,
    output [WIDTH-1:0] o_time,
    output o_tick
);

    localparam IDLE = 2'b00;
    localparam INC = 2'b01;
    localparam DEC = 2'b10;
    localparam CLEAR = 2'b11;

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
        if (i_tick) begin
            if (r_cnt == TICK_CNT - 1) begin
                n_cnt  = 0;
                n_tick = 1;
            end else begin
                n_cnt  = r_cnt + 1;
                n_tick = 0;
            end
        end
        if (mod == CLEAR) begin
            n_cnt = VALUE;
        end else if (mod == INC) begin
            if (r_cnt >= TICK_CNT - 1) begin
                n_cnt = 0;
            end else begin
                n_cnt = r_cnt + 1;
            end
        end else if (mod == DEC) begin
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

module tick_gen_100hz_w (
    input clk,
    input rst,
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
                if(r_cnt == FCOUNT - 1) begin
                    r_cnt <= 0;
                    r_tick <= 1;
                end else begin
                    r_cnt <= r_cnt + 1;
                    r_tick <= 0;
                end
        end
    end

    assign o_tick = r_tick;
endmodule
