`timescale 1ns / 1ps


module fnd_controller_dht (
    input         clk        ,
    input         rst        ,
    input  [39:0] i_data     ,
    output [7:0]  dht_data   ,
    output [3:0]  fnd_com    ,
    output [7:0]  fnd_data   
    );

    wire [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000, w_bcd, w_bcd_dht;
    wire [1:0] w_digit_sel, w_dht_sel;
    wire w_1khz;

    wire [7:0] w_hum;
    wire [7:0] w_temp;

    clk_divider_dht U_CLK_DIV(
        .clk(clk),
        .rst(rst),
        .o_1khz(w_1khz)
    );

    counter_4_dht U_CNT_4(
        .clk(w_1khz),
        .rst(rst),
        .digit_sel(w_digit_sel)
    );

    counter_4_dht U_CNT_DHT_DATA(
        .clk(clk),
        .rst(rst),
        .digit_sel(w_dht_sel)
    );

    bit_divider_dht U_BIT_DIV(
        .i_data     (i_data),
        .o_div_1    (w_hum),
        .o_div_2    (w_temp)
    );

    mux_2x4_dht U_MUX_2X4(
        .sel(w_digit_sel),
        .fnd_com(fnd_com)
    );

    mux_4x1_dht U_MUX_4X1(
    .sel(w_digit_sel),
    .digit_1(w_digit_1),
    .digit_10(w_digit_10),
    .digit_100(w_digit_100),
    .digit_1000(w_digit_1000),
    .bcd_data(w_bcd)
    );

    mux_4x1_dht U_MUX_DHT(
        .sel(w_dht_sel),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000),
        .bcd_data(w_bcd_dht)
    );

    num_to_ascii_dht U_NTA_DHT(
        .bcd   (w_bcd_dht),
        .ascii (dht_data) 
    );

    bcd_decoder_dht U_BCD(
        .bcd(w_bcd),
        .fnd_data(fnd_data)
    );

    digit_spliter_dht U_DIGIT_SP_HUM(
        .i_data     (w_hum),
        .digit_1    (w_digit_1),
        .digit_10   (w_digit_10)
    );

    digit_spliter_dht U_DIGIT_SP_TEMP(
        .i_data     (w_temp),
        .digit_1    (w_digit_100),
        .digit_10   (w_digit_1000)
    );    
endmodule

module bit_divider_dht(
    input  [39:0] i_data     ,
    output [7:0]  o_div_1    ,
    output [7:0]  o_div_2    
);

    reg [7:0] hum_data, temp_data;

    assign o_div_1 = hum_data;
    assign o_div_2 = temp_data;

    always @(*) begin
        if(i_data[39:32] >= 90) begin
            hum_data = 90;
        end else begin
            hum_data = i_data[39:32];
        end

        if(i_data[23:16] >= 50) begin
            temp_data = 50;
        end else begin
            temp_data = i_data[23:16];
        end
    end
endmodule

module num_to_ascii_dht(
    input      [3:0] bcd         ,
    output reg [7:0] ascii      
);
    always @(bcd) begin 
        case (bcd)
            4'h0: ascii = "0";
            4'h1: ascii = "1";
            4'h2: ascii = "2";
            4'h3: ascii = "3";
            4'h4: ascii = "4";
            4'h5: ascii = "5";
            4'h6: ascii = "6";
            4'h7: ascii = "7";  
            4'h8: ascii = "8";
            4'h9: ascii = "9";
            
            default: ascii = "!";
        endcase
    end
endmodule

module clk_divider_dht (
    input clk,
    input rst,
    output reg o_1khz
);
    
    reg [16:0] r_counter;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter <= 0;
            o_1khz <= 1'b0;
        end else begin
            if (r_counter == 100000 - 1) begin
                r_counter <= 0;
                o_1khz <= 1'b1;
            end else begin
                r_counter <= r_counter + 1;
                o_1khz <= 1'b0;
            end
        end
    end
endmodule

module counter_4_dht (
    input clk,
    input rst,
    output [1:0] digit_sel
);

    reg [1:0] r_counter;
    assign digit_sel = r_counter;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            // initialize
            r_counter <= 0;
        end else begin
            // operation
            r_counter <= r_counter + 1;
        end
    end
endmodule

module mux_2x4_dht (
    input [1:0] sel,
    output reg [3:0] fnd_com
);

    always @(*) begin
        case (sel)
            2'b00: fnd_com = 4'b1110;   // digit 1st
            2'b01: fnd_com = 4'b1101;   // digit 10th
            2'b10: fnd_com = 4'b1011;   // digit 100th
            2'b11: fnd_com = 4'b0111;   // digit 1000th
            default: fnd_com = 4'b1111;
        endcase
    end
    
endmodule

module mux_4x1_dht (
    input [1:0] sel,
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    output reg [3:0] bcd_data
);
    
    always @(*) begin
        case (sel)
            2'b00: bcd_data = digit_1;
            2'b01: bcd_data = digit_10;
            2'b10: bcd_data = digit_100;
            2'b11: bcd_data = digit_1000;
            default: bcd_data = digit_1;
        endcase
    end

endmodule

module digit_spliter_dht (
    input  [7:0] i_data     ,
    output [3:0] digit_1    ,
    output [3:0] digit_10   
);
    assign digit_1 = i_data % 10;
    assign digit_10 = i_data / 10 % 10;  
endmodule

module bcd_decoder_dht(
    input [3:0] bcd,
    output reg [7:0] fnd_data
);
    always @(bcd) begin
        case (bcd)
            0: fnd_data = 8'hc0;
            1: fnd_data = 8'hf9;
            2: fnd_data = 8'ha4;
            3: fnd_data = 8'hb0;
            4: fnd_data = 8'h99;
            5: fnd_data = 8'h92;
            6: fnd_data = 8'h82;
            7: fnd_data = 8'hf8;
            8: fnd_data = 8'h80;
            9: fnd_data = 8'h90;
            default: fnd_data = 8'hff;
        endcase
    end
endmodule