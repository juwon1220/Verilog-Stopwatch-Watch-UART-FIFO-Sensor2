`timescale 1ns / 1ps


// module loopback_or_ascii(
//     input sw_14,//0이면 루프백, 1이면 stopwatch 시간 출력
//     input [7:0] tx_lb_data,
//     input [7:0] ascii_data,
//     input tx_empty,
//     input ascii_send_start,
//     input tx_busy,
//     output [7:0] tx_data,
//     output tx_start,
//     output lb_tx_busy,
//     output ascii_tx_busy

//     );
    
//     assign ascii_tx_busy = (sw_14) ? tx_busy : 1'bz;
//     assign lb_tx_busy = (sw_14) ? 1'bz : tx_busy;
//     // assign ascii_tx_busy = (sw_14)&(tx_busy);
//     // assign tx_pop = (~sw_14)&(tx_busy);
//     assign tx_data = (sw_14) ? ascii_data : tx_lb_data;
//     assign tx_start = (sw_14) ? ascii_send_start : ~tx_empty;

// endmodule


module loopback_or_ascii(
    input [14:12]sw,//0이면 루프백, 

    input [7:0] tx_lb_data,
    input [7:0] ascii_data_stopwatch,
    input [7:0] ascii_data_watch,
    input [7:0] ascii_data_timer,
    input [7:0] ascii_data_sr04,
    input [7:0] ascii_data_dht11,

    input tx_empty,
    input ascii_send_start_stopwatch,
    input ascii_send_start_watch,
    input ascii_send_start_timer,
    input ascii_send_start_sr04,
    input ascii_send_start_dht11,
    

    input tx_busy,

    output [7:0] tx_data,
    output tx_start,

    output lb_tx_busy,
    output ascii_stopwatch_tx_busy,
    output ascii_watch_tx_busy,
    output ascii_timer_tx_busy,
    output ascii_sr04_tx_busy,
    output ascii_dht11_tx_busy

    );

    reg r_ascii_stopwatch_tx_busy;
    reg r_ascii_watch_tx_busy;
    reg r_ascii_timer_tx_busy;
    reg r_ascii_sr04_tx_busy;
    reg r_ascii_dht11_tx_busy;

    reg r_lb_tx_busy;

    reg r_tx_start;
    reg [7:0] r_tx_data;

    assign ascii_stopwatch_tx_busy = r_ascii_stopwatch_tx_busy;
    assign ascii_watch_tx_busy = r_ascii_watch_tx_busy;
    assign ascii_timer_tx_busy = r_ascii_timer_tx_busy;
    assign ascii_sr04_busy = r_ascii_sr04_tx_busy;
    assign ascii_dht11_busy = r_ascii_dht11_tx_busy;
    
    assign tx_start = r_tx_start;
    assign tx_data = r_tx_data;
    
    always @(*) begin
        case (sw)
            3'b000: begin   //loopback
                r_lb_tx_busy = tx_busy;
                r_tx_data = tx_lb_data;
                r_tx_start = ~tx_empty;
            end
            3'b001: begin   //stopwatch
                r_ascii_stopwatch_tx_busy = tx_busy;
                r_tx_data = ascii_data_stopwatch;
                r_tx_start = ascii_send_start_stopwatch;
            end
            3'b010: begin   //watch
                r_ascii_watch_tx_busy = tx_busy;
                r_tx_data = ascii_data_watch;
                r_tx_start = ascii_send_start_watch;
            end
            3'b011: begin   //timer
                r_ascii_timer_tx_busy = tx_busy;
                r_tx_data = ascii_data_timer;
                r_tx_start = ascii_send_start_timer;
            end
            3'b1x0: begin   //sr04
                r_ascii_sr04_tx_busy = tx_busy;
                r_tx_data = ascii_data_sr04;
                r_tx_start = ascii_send_start_sr04;
            end
            3'b1x1: begin   //dht11
                r_ascii_dht11_tx_busy = tx_busy;
                r_tx_data = ascii_data_dht11;
                r_tx_start = ascii_send_start_dht11;
            end

            default: begin
                r_lb_tx_busy = tx_busy;
                r_tx_data = tx_lb_data;
                r_tx_start = ~tx_empty;
            end
                
        endcase
    end

    // assign ascii_tx_busy = (sw_14) ? tx_busy : 1'bz;
    // assign lb_tx_busy = (sw_14) ? 1'bz : tx_busy;
    // assign tx_data = (sw_14) ? ascii_data : tx_lb_data;
    // assign tx_start = (sw_14) ? ascii_send_start : ~tx_empty;

endmodule