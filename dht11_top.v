`timescale 1ns / 1ps



module dht11_top(
    input        clk            ,
    input        rst            ,
    input  [7:0] start          ,
    inout        dht_io         ,
    output [7:0] dht_data       ,
    output [7:0] fnd_data       ,   
    output [3:0] fnd_com        ,
    output       done                 
    );

    wire w_tick;
    wire w_vaild;
    wire w_done;
    wire [39:0] w_data;

    counter_divider #(.DIV(1000)) U_CLK_DIV_10US(
        .clk     (clk), 
        .rst     (rst),
        .clk_div (w_tick) 
    );

    fsm_dht11 U_FSM_DHT(
        .clk    (clk)    ,
        .rst    (rst)    ,
        .start  (start)  ,
        .tick   (w_tick) ,
        .dht_io (dht_io) ,
        .data   (w_data)  ,
        .vaild  (vaild)  ,
        .done   (done)   
    );

    fnd_controller_dht U_FND_CTRL_DHT(
        .clk        (clk),
        .rst        (rst),
        .i_data     (w_data),
        .dht_data   (dht_data),
        .fnd_com    (fnd_com),
        .fnd_data   (fnd_data)
    );
endmodule



module counter_divider #(parameter DIV = 1000)(
    input   clk     , 
    input   rst     ,
    output  clk_div  
    );

    // register
    reg [$clog2(DIV)-1:0] count;
    reg tick;

    // output
    assign clk_div = tick;

    // sequential logic
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count <= 0;
            tick  <= 0;
        end else begin
            if(count == DIV - 1) begin
                count <= 0;
                tick <= 1'b1;
            end else begin
                count <= count + 1;
                tick <= 1'b0;
            end
        end
    end
endmodule



module fsm_dht11 (
    input         clk,
    input         rst,
    input  [7:0]  start,
    input         tick,
    inout         dht_io,
    output [39:0] data,
    output        vaild,
    output        done
);

    // State encoding
    parameter IDLE        = 3'd0,
              START_SIG   = 3'd1,
              WAIT_RESP   = 3'd2,
              SYNC_LOW    = 3'd3,
              SYNC_HIGH   = 3'd4,
              PREPARE_BIT = 3'd5,
              READ_BIT    = 3'd6,
              CHECK_SUM   = 3'd7;

    // Internal Registers
    reg [2:0] state_reg, state_next;
    reg [$clog2(2000)-1:0] count_reg, count_next;
    reg [$clog2(40)-1:0] bit_reg, bit_next;
    reg [39:0] data_reg, data_next;
    reg [39:0] final_data_reg, final_data_next;
    reg tx_reg, tx_next;
    reg en_reg, en_next;
    reg done_reg, done_next;
    reg vaild_reg, vaild_next;

    // Wire for checksum calculation
    wire [8:0] sum_1 = data_reg[39:32] + data_reg[31:24];
    wire [8:0] sum_2 = data_reg[23:16] + data_reg[15:8];
    wire [9:0] total = sum_1 + sum_2;

    // Output assigns
    assign dht_io = (en_reg) ? tx_reg : 1'bz;
    assign data   = final_data_reg;
    assign done   = done_reg;
    assign vaild  = vaild_reg;

    // Sequential block
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg <= IDLE;
            count_reg <= 0;
            bit_reg   <= 0;
            data_reg  <= 0;
            tx_reg    <= 1;
            en_reg    <= 1;
            done_reg  <= 0;
            vaild_reg <= 0;
            final_data_reg <= 0;
        end else begin
            state_reg <= state_next;
            count_reg <= count_next;
            bit_reg   <= bit_next;
            data_reg  <= data_next;
            tx_reg    <= tx_next;
            en_reg    <= en_next;
            done_reg  <= done_next;
            vaild_reg <= vaild_next;
            final_data_reg <= final_data_next;
        end
    end

    // Combinational FSM
    always @(*) begin
        // Default assignments
        state_next = state_reg;
        count_next = count_reg;
        bit_next   = bit_reg;
        data_next  = data_reg;
        tx_next    = tx_reg;
        en_next    = en_reg;
        done_next  = done_reg;
        vaild_next = vaild_reg;
        final_data_next = final_data_reg;

        case (state_reg)
            IDLE: begin
                done_next  = 0;
                vaild_next = 0;
                if (start == "T") begin
                    tx_next    = 0;
                    en_next    = 1;
                    count_next = 0;
                    state_next = START_SIG;
                end
            end

            START_SIG: begin
                if (tick) begin
                    if (count_reg >= 1800) begin  // Send 0 for 18ms
                        tx_next    = 1;
                        count_next = 0;
                        state_next = WAIT_RESP;
                    end else begin
                        count_next = count_reg + 1;
                    end
                end
            end

            WAIT_RESP: begin
                if (tick) begin
                    if (count_reg >= 2) en_next = 0; // Release line
                    if (count_reg >= 3 && dht_io == 0) begin
                        count_next = 0;
                        state_next = SYNC_LOW;
                    end else begin
                        count_next = count_reg + 1;
                    end
                end
            end

            SYNC_LOW: begin
                if (tick) begin
                    if (count_reg >= 7 && dht_io == 1) begin
                        count_next = 0;
                        state_next = SYNC_HIGH;
                    end else begin
                        count_next = count_reg + 1;
                    end
                end
            end

            SYNC_HIGH: begin
                if (tick) begin
                    if (count_reg >= 7 && dht_io == 0) begin
                        count_next = 0;
                        state_next = PREPARE_BIT;
                    end else begin
                        count_next = count_reg + 1;
                    end
                end
            end

            PREPARE_BIT: begin
                if (tick) begin
                    if (bit_reg == 40) begin
                        count_next = 0;
                        bit_next   = 0;
                        state_next = CHECK_SUM;
                    end else if (count_reg >= 5 && dht_io == 1) begin
                        count_next = 0;
                        state_next = READ_BIT;
                    end else begin
                        count_next = count_reg + 1;
                    end
                end
            end

            READ_BIT: begin
                if (tick) begin
                    if (dht_io == 0) begin
                        data_next  = {data_reg[38:0], (count_reg < 4) ? 1'b0 : 1'b1};
                        bit_next   = bit_reg + 1;
                        count_next = 0;
                        state_next = PREPARE_BIT;
                    end else begin
                        if (count_reg > 10) begin // Timeout
                            state_next = IDLE;
                            en_next    = 1;
                            tx_next    = 1;
                            count_next = 0;
                        end else begin
                            count_next = count_reg + 1;
                        end
                    end
                end
            end

            CHECK_SUM: begin
                if (tick) begin
                    vaild_next = (total[7:0] == data_reg[7:0]);
                    if (count_reg >= 5 && vaild_reg) begin
                        final_data_next = data_reg;
                        done_next  = 1;
                        tx_next    = 1;
                        en_next    = 1;
                        count_next = 0;
                        state_next = IDLE;
                    end else begin
                        count_next = count_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule