`timescale 1ns / 1ps


module sr04_top(
    input        clk        ,
    input        rst        ,
    input  [7:0] start      ,
    input        echo       ,
    output       trigger    ,
    output [7:0] fnd_data   ,
    output [3:0] fnd_com    ,
    output [7:0] dist_data  ,
    output       done       
);

    wire w_tick;
    wire [11:0] w_dist;

    counter_divider #(.DIV(10)) U_CLK_DIV(
        .clk     (clk), 
        .rst     (rst),
        .clk_div (w_tick) 
    );

    fsm_ultra_sensor U_SENSOR_CU(
        .clk      (clk),
        .rst      (rst),
        .start    (start),
        .echo     (echo),
        .tick     (w_tick),
        .trigger  (trigger),
        .distance (w_dist),
        .done     (done)
    );

    fnd_controller_sr04 U_FND_CTRL(
        .clk       (clk),
        .rst       (rst),
        .i_data    (w_dist),
        .fnd_com   (fnd_com),
        .fnd_data  (fnd_data),
        .dist_data (dist_data)
    );
endmodule

//module counter_divider #(parameter DIV = 1000)(
//    input   clk     , 
//    input   rst     ,
//    output  clk_div  
//    );
//
//    // register
//    reg [$clog2(DIV)-1:0] count;
//    reg tick;
//
//    // output
//    assign clk_div = tick;
//
//    // sequential logic
//    always @(posedge clk, posedge rst) begin
//        if (rst) begin
//            count <= 0;
//            tick  <= 0;
//        end else begin
//            if(count == DIV - 1) begin
//                count <= 0;
//                tick <= 1'b1;
//            end else begin
//                count <= count + 1;
//                tick <= 1'b0;
//            end
//        end
//    end
//endmodule

module fsm_ultra_sensor(
    input         clk      ,
    input         rst      ,
    input  [7:0]  start    ,
    input         echo     ,
    input         tick     ,
    output        trigger  ,
    output [11:0] distance ,
    output        done     
);

    /////////////////////////////////////
    // SR-04 Ultra Sensor Control Unit //
    // maximum distance = 400cm        //
    // distance formula = uS/58        //
    /////////////////////////////////////

    // parameter
    parameter IDLE = 0, START = 1, WAIT = 2, DETECTION = 3, CAL = 4;

    // register
    reg [2:0] state_reg, state_next;
    reg [$clog2(4000*58*1130)-1:0] dist_reg, dist_next, r_result, n_result;
    reg [$clog2(4000*58)-1:0] count_reg, count_next;
    reg trig_reg, trig_next;
    reg done_reg, done_next;

    // output
    assign distance = r_result;
    assign trigger  = trig_reg;
    assign done     = done_reg;

    // sequential logic
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state_reg <= 0;
            trig_reg  <= 0;
            count_reg <= 0;
            dist_reg  <= 0;
            done_reg  <= 0;
            r_result     <= 0;
        end else begin
            state_reg <= state_next;
            trig_reg  <= trig_next;
            count_reg <= count_next;
            dist_reg  <= dist_next;
            done_reg  <= done_next;
            r_result   <= n_result;
        end
    end

    // combinational logic
    always @(*) begin
        state_next = state_reg;
        trig_next  = trig_reg;
        count_next = count_reg;
        dist_next  = dist_reg;
        done_next  = done_reg;
        n_result   = r_result;
        case (state_reg)
            IDLE: begin
                trig_next  = 0;
                count_next = 0;
                done_next  = 0;
                if (start == "T") begin
                    trig_next  = 1;
                    state_next = START;
                end
            end
            START: begin
                if (tick) begin
                    if (count_reg == 10) begin
                        trig_next  = 0;
                        count_next = 0;
                        state_next = WAIT;
                    end else begin
                        count_next = count_reg + 1;
                    end
                end
            end
            WAIT: begin
                if (echo && tick) begin
                    state_next = DETECTION;
                end
            end
            DETECTION: begin
                if (!echo) begin
                    dist_next  = count_reg;
                    state_next = CAL;
                end else begin
                    if (tick) begin
                        count_next = count_reg + 1;
                    end
                end
            end
            CAL: begin
                done_next  = 1;
                n_result = (dist_reg * 1130) >> 16;
                state_next = IDLE;
            end
        endcase
    end
endmodule