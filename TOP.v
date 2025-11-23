`timescale 1ns / 1ps

module swt_top(
    input        clk       ,
    input        rst       ,
    input [7:0]  rx_data   ,
    input        tx_empty  ,
    input [2:0]  sw        ,       // sw[1]: 모드 선택 (0 = stopwatch, 1 = watch) sw[2] : timer
    input        sw_priority,   //0=UART 우선 모드, 1=switch 우선 모드
    input        btn_L     ,
    input        btn_R     ,
    input        btn_U     ,
    input        btn_D     ,
    input        fnd_com_dht,
    input        fnd_com_sr,
    input        fnd_data_dht,
    input        fnd_data_sr,
    output [3:0] fnd_com   ,
    output [7:0] fnd_data  ,
    output [3:0] state_led ,
    output [7:0] led,
    output       timer_led,
    output [7:0] stopwatch_data,
    output [7:0] watch_data,
    output [7:0] timer_data,
    output [2:0] mode
);

    // 내부 연결 신호 (watch/stopwatch 각각)
    wire [7:0] fnd_data_watch, fnd_data_stopwatch, fnd_data_timer;
    wire [3:0] fnd_com_watch, fnd_com_stopwatch, fnd_com_timer, w_state_led;

    wire w_btn_R, w_btn_L, w_btn_U, w_btn_D, w_btn_S;
    wire [7:0] w_mode;
    wire [7:0] w_p_out;

    reg [2:0] c_mode, n_mode;
    //reg c_time, n_time;
    

    // LED 상태 출력
    // assign led = ((~m_sel) & (sw[0] == 0)) ? 4'b0001 : 
    //              ((~m_sel) & (sw[0] == 1)) ? 4'b0010 :
    //              ((m_sel) & (sw[0] == 0)) ? 4'b0100 :
    //                              4'b1000 ;
    wire [2:0] m_sel;
    assign led =    (m_sel == 3'b000) ? 8'b0000_0001 :
                    (m_sel == 3'b001) ? 8'b0000_0010 :
                    (m_sel == 3'b010) ? 8'b0000_0100 :
                    (m_sel == 3'b011) ? 8'b0000_1000 :
                    (m_sel == 3'b100) ? 8'b0001_0000 :
                    (m_sel == 3'b101) ? 8'b0010_0000 :
                    (m_sel == 3'b110) ? 8'b0100_0000 :
                    (m_sel == 3'b111) ? 8'b1000_0000 :
                    8'b0000_0000;
    assign state_led = ((c_mode == 2)|(c_mode == 3)) ? w_state_led : 4'b0000;

    assign mode = c_mode;


    // fnd_com와 fnd_data는 sw[1]에 따라 선택
    // assign fnd_com = (~m_sel) ? fnd_com_stopwatch : fnd_com_watch;
    // assign fnd_data = (~m_sel) ? fnd_data_stopwatch : fnd_data_watch;
    assign fnd_com = (c_mode == 7) ? fnd_com_dht :
                     (c_mode == 6) ? fnd_com_sr :
                     ((c_mode == 4)|(c_mode == 5)) ? fnd_com_timer :
                     ((c_mode == 0)|(c_mode == 1)) ? fnd_com_stopwatch : fnd_com_watch;
    assign fnd_data = (c_mode == 7) ? fnd_data_dht :
                      (c_mode == 6) ? fnd_data_sr :
                      ((c_mode == 4)|(c_mode == 5)) ? fnd_data_timer :
                      ((c_mode == 0)|(c_mode == 1)) ? fnd_data_stopwatch : fnd_data_watch;
    // assign state_led = (m_sel) ? w_state_led : 4'b0000;
    //assign state_led = (c_mode==0) ? 4'b0001 : (c_mode == 1) ? 4'b0010 : (c_mode == 2) ? 4'b0100 : (c_mode == 3) ? 4'b1000 : 4'b0000; 

    parameter STOPWATCH_MS = 0, STOPWATCH_MH = 1, WATCH_MS = 2, WATCH_MH = 3, TIMER_MS = 4, TIMER_MH = 5, SR04 = 6, DHT11 = 7;
    
    //assign m_sel = (c_mode == STOPWATCH) ? 1'b0 : 1'b1;
    //assign m_sel = (c_mode == 2'b00) ? 2'b00 : (c_mode == 2'b01) ? 2'b01 : (c_mode == 2'b10) ? 2'b10 : (c_mode == 2'b11) ? 2'b11;
    assign m_sel = c_mode;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_mode <= STOPWATCH_MS;
        end else begin
            c_mode <= n_mode;
        end
    end

    always @(*) begin
        n_mode = c_mode;
        if (sw_priority == 1'b0) begin // UART 우선 모드
            case (c_mode)
                STOPWATCH_MS: begin
                    if((~tx_empty)&(rx_data == 8'h4d)) begin //"M"   원래 1 자리에 ~tx_empty
                        n_mode = STOPWATCH_MH;
                    end
                end 
                STOPWATCH_MH: begin
                    if((~tx_empty)&(rx_data == 8'h4d)) begin //"M"
                        n_mode = WATCH_MS;
                    end
                end 
                WATCH_MS: begin
                    if((~tx_empty)&(rx_data == 8'h4d)) begin
                        n_mode = WATCH_MH;
                    end
                end
                WATCH_MH: begin
                    if((~tx_empty)&(rx_data == 8'h4d)) begin
                        n_mode = TIMER_MS;
                    end
                end
                TIMER_MS: begin
                    if((~tx_empty)&(rx_data == 8'h4d)) begin
                        n_mode = TIMER_MH;
                    end
                end
                TIMER_MH: begin
                    if((~tx_empty)&(rx_data == 8'h4d)) begin
                        n_mode = SR04;
                    end
                end
                SR04: begin
                    if((~tx_empty)&(rx_data == 8'h4d)) begin
                        n_mode = DHT11;
                    end
                end
                DHT11: begin
                    if((~tx_empty)&(rx_data == 8'h4d)) begin
                        n_mode = STOPWATCH_MS;
                    end
                end
                default: n_mode = c_mode; 
            endcase
        end else begin //sw 우선 모드

            case (sw)
                STOPWATCH_MS : begin
                    n_mode = STOPWATCH_MS;
                end
                STOPWATCH_MH : begin
                    n_mode = STOPWATCH_MH;
                end
                WATCH_MS : begin
                    n_mode = WATCH_MS;
                end
                WATCH_MH : begin
                    n_mode = WATCH_MH;
                end
                TIMER_MS : begin
                    n_mode = TIMER_MS;
                end
                TIMER_MH : begin
                    n_mode = TIMER_MH;
                end
                SR04 : begin
                    n_mode = SR04;
                end
                DHT11 : begin
                    n_mode = DHT11;
                end
                default: n_mode = TIMER_MS;
            endcase
            /*
            if(sw == 2'b00) begin
                n_mode = STOPWATCH_MS;
            end else if (sw == 2'b01) begin
                n_mode = STOPWATCH_MH;
            end else if (sw == 2'b10) begin
                n_mode = WATCH_MS;
            end else if (sw == 2'b11) begin
                n_mode = WATCH_MH;
            end else n_mode = 2'b00; */
        end
    end


    // hex_pulse_gen#(.DIV(2_000)) HP_BTN_DBC(
    //     .clk      (clk),
    //     .rst      (rst),
    //     .rx_data  (rx_data),
    //     .tx_empty (tx_empty),
    //     .p_out    (w_p_out)
    // );

    // 스톱워치 모듈
    stopwatch U_SW(
        .clk(clk),
        .rst(rst), //"S"
        .sw(sw[0]|(m_sel[0])),
        .btn_L(btn_L),  // clear //"L"
        .btn_R(btn_R),  // run_stop  //"R"
        .tx_empty(tx_empty),
        .rx_data(rx_data),
        .fnd_com(fnd_com_stopwatch),
        .fnd_data(fnd_data_stopwatch),
        .stopwatch_data(stopwatch_data)
    );

    // 시계 모듈
    watch U_WATCH(
        .clk(clk),
        .rst(rst),
        .sw(sw[0]|(m_sel[0])),
        .btn_L(btn_L),  // clear "L"
        .btn_R(btn_R),  // digit move "R"
        .btn_U(btn_U),  // increase "U"
        .btn_D(btn_D),  // decrease "D"
        .tx_empty(tx_empty),
        .rx_data(rx_data),
        .state_led(w_state_led),
        .fnd_com(fnd_com_watch),
        .fnd_data(fnd_data_watch),
        .watch_data(watch_data)
    );

    // 타이머
    timer U_TIMER(
        .clk(clk),
        .rst(rst),
        .sw(sw[0]|m_sel[0]),
        .btn_L(btn_L), // clear
        .btn_R(btn_R), // digit_move
        .btn_U(btn_U), // increase
        .btn_D(btn_D), // decrease
        .tx_empty(tx_empty),
        .rx_data(rx_data),
        .fnd_com(fnd_com_timer),
        .fnd_data(fnd_data_timer),
        .timer_led(timer_led),
        .timer_data(timer_data)
    );
endmodule
