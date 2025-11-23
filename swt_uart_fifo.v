`timescale 1ns / 1ps

module TOP(
    input        clk       ,
    input        rst       ,
    input        rx        ,
    input [2:0]  sw        ,
    input [14:12] ascii_sw ,
    input        sw_priority,
    input        btn_L     ,
    input        btn_R     ,
    input        btn_U     ,
    input        btn_D     ,

    input        echo,
    inout        dht_io,
    output       trig,

    output [3:0] fnd_com   ,
    output [7:0] fnd_data  ,
    output [3:0] state_led ,    //4개
    output [7:0] led       ,    //8개
    output [10:8] ascii_led,    //3개
    output       timer_led,     //1개
    output tx                             
);

    wire [7:0] w_rx_data;
    wire w_tx_empty;
    wire [7:0] w_stopwatch_data, w_watch_data, w_timer_data;
    wire [7:0] w_sr04_data, w_dht11_data;

    // uart_fifo U_UART_FIFO(
    //     .clk      (clk),
    //     .rst      (rst),
    //     .rx       (rx),
    //     .rx_data  (w_rx_data),
    //     .tx_empty (w_tx_empty),
    //     .tx       (tx)
    // );
    wire w_dht_done, w_sr_done;

    uart_fifo U_UART_FIFO(
        .clk      (clk),
        .rst      (rst),
        .rx       (rx),
        .ascii_sw (ascii_sw),   //// 0이면 루프백, 1이면 ascii_sender의 data
        .sw_priority(sw_priority),
        .stopwatch_data(w_stopwatch_data),   ////ascii sender의 input으로 감
        .watch_data(w_watch_data),
        .timer_data(w_timer_data),
        .sr04_data(w_sr04_data),
        .dht11_data(w_dht11_data),
        .dht_done (w_dht_done),
        .sr_done  (w_sr_done),
        .rx_data  (w_rx_data),
        .tx_empty (w_tx_empty),
        .tx       (tx)
        //.ascii_mode (w_ascii_mode)
    );

    wire [7:0] w_fnd_data_dht, w_fnd_data_sr;
    wire [3:0] w_fnd_com_dht, w_fnd_com_sr;

    wire [2:0] w_mode;

    swt_top U_SWT_TOP(
        .clk       (clk),
        .rst       (rst),
        .rx_data   (w_rx_data),
        .tx_empty  (w_tx_empty),///
        .sw        (sw),
        .sw_priority(sw_priority),
        .btn_L     (btn_L),
        .btn_R     (btn_R),
        .btn_U     (btn_U),
        .btn_D     (btn_D),
        .fnd_com_dht(w_fnd_com_dht),
        .fnd_com_sr(w_fnd_com_sr),
        .fnd_data_dht(w_fnd_data_dht),
        .fnd_data_sr(w_fnd_data_sr),
        .fnd_com   (fnd_com),
        .fnd_data  (fnd_data),
        .state_led (state_led),
        .led       (led),
        .timer_led (timer_led),
        .stopwatch_data(w_stopwatch_data),
        .watch_data(w_watch_data),
        .timer_data(w_timer_data),
        .mode(w_mode)
        //.ascii_mode  (w_ascii_mode)
    );



    //dht11_top DHT11_TOP(
    //    input        clk(clk)            ,
    //    input        rst(rst)            ,
    //    input  [7:0] start("T")          ,//////////////////////////
    //    inout        dht_io(dht_io)         ,
    //    output [7:0] dht_data(w_dht_data)       ,
    //    output [7:0] fnd_data()       ,   
    //    output [3:0] fnd_com()        ,
    //    output [7:0] led()            ,
    //    output       done()                 
    //    );

    //sr04_top SR04_TOP(
    //    input        clk(clk),
    //    input        rst(rst),
    //    input        echo(echo),
    //    input        rx(),
    //    output       tx(),
    //    output       trig(trig),
    //    output [3:0] fnd_com(),
    //    output [7:0] fnd_data()
    //);

    sr04_top SR04_TOP(
        .clk(clk)        ,
        .rst(rst | ((~w_tx_empty)&(w_rx_data == "S")))        ,
        .start((w_rx_data=="T")&{8{( w_mode == 6)}})      ,     //8bit
        .echo(echo)       ,
        .trigger(trig)    ,
        .fnd_data(w_fnd_data_sr)   ,
        .fnd_com(w_fnd_com_sr)    ,
        .dist_data(w_sr04_data)  ,
        .done(w_sr_done)       
    );

    dht11_top DHT11_TOP(
        .clk(clk)            ,
        .rst(rst | ((~w_tx_empty)&(w_rx_data == "S")))            ,
        .start((w_rx_data=="T")&{8{( w_mode == 7)}})          , //8bit
        .dht_io(dht_io)         ,
        .dht_data(w_dht11_data)       ,
        .fnd_data(w_fnd_data_dht)       ,   
        .fnd_com(w_fnd_com_dht)        ,
        .done(w_dht_done)                 
    );

    


    

   


endmodule
