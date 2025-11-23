`timescale 1ns / 1ps


module uart_fifo(
    input        clk      ,
    input        rst      ,
    input        rx       ,
    input  [14:12] ascii_sw, ////
    input       sw_priority,
    input  [7:0] stopwatch_data,
    input  [7:0] watch_data,
    input  [7:0] timer_data,
    input  [7:0] sr04_data,
    input  [7:0] dht11_data,
    input        dht_done,
    input        sr_done,
    output [7:0] rx_data  ,
    output       tx_empty  ,
    output       tx
    //input  [2:0] ascii_mode
);



    wire [7:0] w_tx_data, w_ascii_data, w_tf_data, w_rx_data, w_lb_data;
    wire w_tx_busy, w_tx_start, w_ascii_tx_busy, w_lb_tx_busy, w_ascii_send_start, w_tx_empty;
    wire w_rx_done, w_lb_empty, w_lb_full;

    wire [7:0] w_ascii_stopwatch_data, w_ascii_watch_data, w_ascii_timer_data, w_ascii_sr04_data, w_ascii_dht11_data;
    wire w_ascii_send_start_stopwatch, w_ascii_send_start_watch, w_ascii_send_start_timer, w_ascii_send_start_sr04, w_ascii_send_start_dht11;
    wire w_ascii_stopwatch_tx_busy, w_ascii_watch_tx_busy, w_ascii_timer_tx_busy, w_ascii_sr04_tx_busy, w_ascii_dht11_tx_busy;

    assign rx_data = w_lb_data;
    assign tx_empty = w_lb_empty;



    reg [2:0] c_ascii_mode, n_ascii_mode;
    wire [2:0] w_ascii_mode;
    wire [2:0] w_ascii_date;
    assign w_ascii_mode = c_ascii_mode;
    assign ascii_led = c_ascii_mode;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_ascii_mode <= 0;
            
        end else begin
            c_ascii_mode <= n_ascii_mode;
        end
    end

    always @(*) begin
        n_ascii_mode = c_ascii_mode;
        if (!sw_priority) begin //UART 우선모드
            case (c_ascii_mode)
                3'b000: begin   //loopback
                    if ((w_tx_empty)&(w_rx_data == "A")) begin
                        n_ascii_mode = 3'b001;
                    end
                end
                3'b001: begin   //stopwatch
                    if ((w_tx_empty)&(w_rx_data == "A")) begin
                        n_ascii_mode = 3'b010;
                    end
                end 
                3'b010: begin   //watch
                    if ((w_tx_empty)&(w_rx_data == "A")) begin
                        n_ascii_mode = 3'b011;
                    end
                end 
                3'b011: begin   //timer
                    if ((w_tx_empty)&(w_rx_data == "A")) begin
                        n_ascii_mode = 3'b100;
                    end
                end 
                3'b1x0: begin   //sr04
                    if ((w_tx_empty)&(w_rx_data == "A")) begin
                        n_ascii_mode = 3'b101;
                    end
                end 
                3'b1x1: begin   //dht11
                    if ((w_tx_empty)&(w_rx_data == "A")) begin
                        n_ascii_mode = 3'b000;
                    end
                end
                default: n_ascii_mode = c_ascii_mode;
            endcase
        end else begin  //SWITCH 우선모드
            case (ascii_sw)
                3'b000: begin   //loopback
                    n_ascii_mode = 3'b000;
                end
                3'b001: begin   //stopwatch
                    n_ascii_mode = 3'b001;
                end 
                3'b010: begin   //watch
                    n_ascii_mode = 3'b010;
                end 
                3'b011: begin   //timer
                    n_ascii_mode = 3'b011;
                end 
                3'b1x0: begin   //sr04
                    n_ascii_mode = 3'b100;
                end 
                3'b1x1: begin   //dht11
                    n_ascii_mode = 3'b101;
                end
                default: begin
                    n_ascii_mode = 3'b000;
                end
            endcase
            
        end
    end

    //output
    // always @(posedge clk, posedge rst) begin
    //     if (rst) begin
    //         rx_data_reg <= 0;
    //     end else begin
    //         if(!w_lb_push) begin
    //             rx_data_reg <= w_lb_data;
    //         end else rx_data_reg <= 0; 
    //     end
    // end

    // loopback
    uart U_UART(
        .clk(clk),
        .rst(rst),
        .tx_start(w_tx_start),
        .rx(rx),
        .tx_data(w_tx_data),
        .tx(tx),
        .tx_busy(w_tx_busy),
        .rx_data(w_rx_data),
        .rx_busy(),
        .rx_done(w_rx_done)
    );

    fifo U_FIFO_RX(
        .clk    (clk),
        .rst    (rst),
        .w_data (w_rx_data),
        .push   (w_rx_done),
        .pop    (~(w_lb_full)),
        .r_data (w_lb_data),
        .full   (),
        .empty  (w_lb_empty)
    );

    

    ascii_sender_stopwatch U_ASCII_SENDER_STOPWATCH(
        .clk        (clk),
        .rst        (rst),
        .start      ((c_ascii_mode == 3'b001)&(w_lb_data == "T")&(~w_lb_empty)),
        .tx_busy    (w_ascii_stopwatch_tx_busy),
        .time_data  (stopwatch_data), 
        .send_start (w_ascii_send_start_stopwatch),
        .ascii_data (w_ascii_stopwatch_data)
    );

    ascii_sender_watch U_ASCII_SENDER_WATCH(
        .clk        (clk),
        .rst        (rst),
        .start      ((c_ascii_mode == 3'b010)&(w_lb_data == "T")&(~w_lb_empty)),
        .tx_busy    (w_ascii_watch_tx_busy),
        .time_data  (watch_data), 
        .send_start (w_ascii_send_start_watch),
        .ascii_data (w_ascii_watch_data)
    );

    ascii_sender_timer U_ASCII_SENDER_TIMER(
        .clk        (clk),
        .rst        (rst),
        .start      ((c_ascii_mode == 3'b011)&(w_lb_data == "T")&(~w_lb_empty)),
        .tx_busy    (w_ascii_timer_tx_busy),
        .time_data  (timer_data), 
        .send_start (w_ascii_send_start_timer),
        .ascii_data (w_ascii_timer_data)
    );

    ascii_sender_SR04 U_ASCII_SENDER_SR04(
        .clk        (clk),
        .rst        (rst),
        .start      ((sr_done)&(c_ascii_mode == 3'b100)&(~w_lb_empty)),      //T를 없애야되나   &(w_lb_data == "T")
        .tx_busy    (w_ascii_sr04_tx_busy),
        .sr04_data  (sr04_data), 
        .send_start (w_ascii_send_start_sr04),
        .ascii_data (w_ascii_sr04_data)
    );

    ascii_sender_DHT11 U_ASCII_SENDER_DHT11(
        .clk        (clk),
        .rst        (rst),
        .start      ((sr_done)&(c_ascii_mode == 3'b101)&(~w_lb_empty)),     //T를 없애야되나   &(w_lb_data == "T")
        .tx_busy    (w_ascii_dht11_tx_busy),
        .humid_temp  (dht11_data), 
        .send_start (w_ascii_send_start_dht11),
        .ascii_data (w_ascii_dht11_data)
    );

    

    // loopback_or_ascii U_LOOPBACK_ASCII(
    // .sw_14(sw_14),//0이면 루프백, 1이면 stopwatch 시간 출력
    // .tx_lb_data(w_tf_data),
    // .ascii_data(w_ascii_data),
    // .tx_empty(w_tx_empty),
    // .ascii_send_start(w_ascii_send_start),
    // .tx_busy(w_tx_busy),
    // .tx_data(w_tx_data),
    // .tx_start(w_tx_start),// ~(w_tx_empty)
    // .lb_tx_busy(w_lb_tx_busy),
    // .ascii_tx_busy(w_ascii_tx_busy)

    // );



    loopback_or_ascii U_LOOPBACK_OR_ASCII(
        .sw(ascii_sw),//0이면 루프백, 1이면 stopwatch 시간 출력
        .tx_lb_data(w_tf_data),
        .ascii_data_stopwatch(w_ascii_stopwatch_data),
        .ascii_data_watch(w_ascii_watch_data),
        .ascii_data_timer(w_ascii_timer_data),
        .ascii_data_sr04(w_ascii_sr04_data),
        .ascii_data_dht11(w_ascii_dht11_data),
        .tx_empty(w_tx_empty),
        .ascii_send_start_stopwatch(w_ascii_send_start_stopwatch),
        .ascii_send_start_watch(w_ascii_send_start_watch),
        .ascii_send_start_timer(w_ascii_send_start_timer),
        .ascii_send_start_sr04(w_ascii_send_start_sr04),
        .ascii_send_start_dht11(w_ascii_send_start_dht11),
        .tx_busy(w_tx_busy),
        .tx_data(w_tx_data),
        .tx_start(w_tx_start),
        .lb_tx_busy(w_lb_tx_busy),
        .ascii_stopwatch_tx_busy(w_ascii_stopwatch_tx_busy),
        .ascii_watch_tx_busy(w_ascii_watch_tx_busy),
        .ascii_timer_tx_busy(w_ascii_timer_tx_busy),
        .ascii_sr04_tx_busy(w_ascii_sr04_tx_busy),
        .ascii_dht11_tx_busy(w_ascii_dht11_tx_busy)

    );

    fifo U_FIFO_TX(
        .clk    (clk),
        .rst    (rst),
        .w_data (w_lb_data), //w_time_data
        .push   (~(w_lb_empty)), //w_send_start
        .pop    (~(w_lb_tx_busy)), 
        .r_data (w_tf_data),
        .full   (w_lb_full),
        .empty  (w_tx_empty)
    );




    
endmodule

module uart(
    input        clk,
    input        rst,
    input        tx_start,
    input        rx,
    input  [7:0] tx_data,
    output       tx,
    output       tx_busy,
    output [7:0] rx_data,
    output       rx_busy,
    output       rx_done
);

    wire w_b_tick;

    uart_rx U_UART_RX(
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick), // same b_tick with UART TX
        .rx(rx),
        .rx_data(rx_data),
        .rx_busy(rx_busy),
        .rx_done(rx_done)
    );

    uart_tx U_UART_TX(
        .clk(clk),
        .rst(rst),
        .start(tx_start),
        .b_tick(w_b_tick), // same b_tick with UART RX
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    baud_tick_gen #(.BAUD(9600)) U_BT_GEN(
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick)
    );
endmodule