`timescale 1ns / 1ps

module fnd_controller_sr04 (
    input          clk      ,
    input          rst      ,
    input  [11:0]  i_data   ,
    output [3:0]   fnd_com  ,
    output [7:0]   fnd_data ,
    output [7:0]   dist_data
    );

    wire [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000, w_bcd, w_dist_bcd;
    wire [2:0] w_digit_sel;
    wire [1:0] w_dist_sel;
    wire w_1khz;

    clk_divider_sr04 U_CLK_DIV(
        .clk(clk),
        .rst(rst),
        .o_1khz(w_1khz)
    );

    counter_8_sr04 U_CNT_8(
        .clk(w_1khz),
        .rst(rst),
        .digit_sel(w_digit_sel)
    );

    counter_4_sr04 U_CNT_4_SR(
        .clk(clk),
        .rst(rst),
        .digit_sel(w_dist_sel)
    );

    mux_2x4_sr04 U_MUX_2X4(
        .sel(w_digit_sel[1:0]),
        .fnd_com(fnd_com)
    );

    mux_8x1_sr04 U_MUX_8X1(
    .sel(w_digit_sel),
    .digit_1(w_digit_1),
    .digit_10(w_digit_10),
    .digit_100(w_digit_100),
    .digit_1000(w_digit_1000),
    .bcd_data(w_bcd)
    );

    mux_4x1_sr04 U_MUX_SR_DATA(
    .sel(w_dist_sel),
    .digit_1(w_digit_1),
    .digit_10(w_digit_10),
    .digit_100(w_digit_100),
    .digit_1000(w_digit_1000),
    .bcd_data(w_dist_bcd)
    );

    num_to_ascii_sr04 U_NTA_SR04(
        .bcd        (w_dist_bcd),
        .ascii      (dist_data)
    );

    bcd_decoder_sr04 U_BCD(
        .bcd(w_bcd),
        .fnd_data(fnd_data)
    );

    digit_spliter_sr04 U_DS(
        .i_data(i_data),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000)
    );
endmodule

module num_to_ascii_sr04(
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


module clk_divider_sr04 (
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

module counter_8_sr04 (
    input clk,
    input rst,
    output [2:0] digit_sel
);

    reg [2:0] r_counter;
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

module counter_4_sr04 (
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

module mux_2x4_sr04 (
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

module mux_8x1_sr04 (
    input [2:0] sel,
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    output reg [3:0] bcd_data
);
    always @(*) begin
        case (sel)
            3'b000: bcd_data = digit_1;
            3'b001: bcd_data = digit_10;
            3'b010: bcd_data = digit_100;
            3'b011: bcd_data = digit_1000;
            3'b100: bcd_data = 11;
            3'b101: bcd_data = 10;
            3'b110: bcd_data = 11;
            3'b111: bcd_data = 11;
            default: bcd_data = digit_1;
        endcase
    end
endmodule

module mux_4x1_sr04 (
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

module digit_spliter_sr04 (
    input [11:0] i_data,
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100,
    output [3:0] digit_1000
);
    assign digit_1 = i_data % 10;
    assign digit_10 = i_data / 10 % 10;
    assign digit_100 = i_data / 100 % 10;
    assign digit_1000 = i_data / 1000 % 10;    
endmodule

module bcd_decoder_sr04(
    input [3:0] bcd,
    output reg [7:0] fnd_data   // reg type
);
    always @(bcd) begin   // behavioral modeling : output of always phrase can be only reg type
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
            10: fnd_data = 8'h7f;
            11: fnd_data = 8'hff;
            default: fnd_data = 8'hff;
        endcase
    end
endmodule