`timescale 1ns / 1ps

module fnd_controller_swt (
    input       clk,
    input       rst,
    input       sw,
    input [6:0] msec,
    input [5:0] sec,
    input [5:0] min,
    input [4:0] hour,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output [7:0] time_data
    );

    wire [3:0] w_digit_msec_1, w_digit_msec_10, w_digit_sec_1, w_digit_sec_10;
    wire [3:0] w_digit_min_1, w_digit_min_10, w_digit_hour_1, w_digit_hour_10;
    wire [3:0] w_bcd, w_bcd_temp_1, w_bcd_temp_2, w_bcd_temp_3;
    wire [2:0] w_digit_sel, w_sel;
    wire dot_signal;
    wire w_1khz;

    clk_divider_swt U_CLK_DIV_SWT(
        .clk(clk),
        .rst(rst),
        .o_1khz(w_1khz)
    );

    counter_8_swt U_CNT_8_SWT(
        .clk(w_1khz),
        .rst(rst),
        .digit_sel(w_digit_sel)
    );

    counter_8_swt U_CNT_8_2_SWT( /////
        .clk(clk),
        .rst(rst),
        .digit_sel(w_sel)
    );

    decoder_2x4_swt U_DEC_2X4_SWT(
        .sel(w_digit_sel[1:0]),
        .fnd_com(fnd_com)
    );

    mux_2x1_swt U_MUX_SELECT_MODE_SWT(
        .sel(sw),
        .i_bcd_1(w_bcd_temp_1),
        .i_bcd_2(w_bcd_temp_2),
        .o_bcd(w_bcd)
    );

    dot_comparator_swt U_DC_SWT(
        .msec(msec),
        .dot_signal(w_dot_signal)
    );

    mux_8x1_swt U_MUX_MSEC_SEC_DOT_SWT(
    .sel(w_digit_sel),
    .digit_1(w_digit_msec_1),
    .digit_10(w_digit_msec_10),
    .digit_100(w_digit_sec_1),
    .digit_1000(w_digit_sec_10),
    .digit_off_1(4'he),
    .digit_off_10(4'he),
    .digit_dot({3'b111, w_dot_signal}),
    .digit_off_1000(4'he),
    .bcd_data(w_bcd_temp_1)
    );

    mux_8x1_swt U_MUX_MIN_HOUR_DOT_SWT(
    .sel(w_digit_sel),
    .digit_1(w_digit_min_1),
    .digit_10(w_digit_min_10),
    .digit_100(w_digit_hour_1),
    .digit_1000(w_digit_hour_10),
    .digit_off_1(4'he),
    .digit_off_10(4'he),
    .digit_dot({3'b111, w_dot_signal}),
    .digit_off_1000(4'he),
    .bcd_data(w_bcd_temp_2)
    );

    mux_8x1_swt U_TIME_DATA_OUT_SWT( //
    .sel(w_sel),
    .digit_1(w_digit_msec_1),
    .digit_10(w_digit_msec_10),
    .digit_100(w_digit_sec_1),
    .digit_1000(w_digit_sec_10),
    .digit_off_1(w_digit_min_1),
    .digit_off_10(w_digit_min_10),
    .digit_dot(w_digit_hour_1),
    .digit_off_1000(w_digit_hour_10),
    .bcd_data(w_bcd_temp_3)
    );

    num_to_ascii_swt U_NTA_SWT( //
        .bcd   (w_bcd_temp_3),
        .ascii (time_data)
    );

    bcd_decoder_swt U_BCD_SWT(
        .bcd(w_bcd),
        .fnd_data(fnd_data)
    );

    digit_spliter_swt #(.DS_WIDTH(5)) U_DS_HOUR(
        .i_data(hour),
        .digit_1(w_digit_hour_1),
        .digit_10(w_digit_hour_10)
    );

    digit_spliter_swt #(.DS_WIDTH(6)) U_DS_MIN(
        .i_data(min),
        .digit_1(w_digit_min_1),
        .digit_10(w_digit_min_10)
    );

    digit_spliter_swt #(.DS_WIDTH(6)) U_DS_SEC(
        .i_data(sec),
        .digit_1(w_digit_sec_1),
        .digit_10(w_digit_sec_10)
    );

    digit_spliter_swt #(.DS_WIDTH(7)) U_DS_MSEC(
        .i_data(msec),
        .digit_1(w_digit_msec_1),
        .digit_10(w_digit_msec_10)
    );
endmodule

module num_to_ascii_swt(
    input [3:0] bcd,
    output reg [7:0] ascii
);
    always @(bcd) begin   // behavioral modeling : output of always phrase can be only reg type
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

module dot_comparator_swt (
    input [6:0] msec,
    output dot_signal
);

    assign dot_signal = (msec >= 50) ? 1'b1 : 1'b0;
endmodule

module clk_divider_swt (
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

module counter_8_swt (
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

module decoder_2x4_swt (
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

module mux_2x1_swt (
    input sel,
    input [3:0] i_bcd_1,
    input [3:0] i_bcd_2,
    output reg [3:0] o_bcd
);

    always @(*) begin
        case (sel)
            1'b0: o_bcd = i_bcd_1; // msec & sec mode
            1'b1: o_bcd = i_bcd_2; // min & hour mode
            default: o_bcd = i_bcd_1;
        endcase
    end
    
endmodule

module mux_8x1_swt (
    input [2:0] sel,
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    input [3:0] digit_off_1,
    input [3:0] digit_off_10,
    input [3:0] digit_dot,
    input [3:0] digit_off_1000,
    output reg [3:0] bcd_data
);
    
    always @(*) begin
        case (sel)
            3'b000: bcd_data = digit_1;
            3'b001: bcd_data = digit_10;
            3'b010: bcd_data = digit_100;
            3'b011: bcd_data = digit_1000;
            3'b100: bcd_data = digit_off_1;
            3'b101: bcd_data = digit_off_10;
            3'b110: bcd_data = digit_dot;
            3'b111: bcd_data = digit_off_1000;
            default: bcd_data = digit_1;
        endcase
    end
endmodule

module digit_spliter_swt #(parameter DS_WIDTH = 7) (
    input [DS_WIDTH-1:0] i_data,
    output [3:0] digit_1,
    output [3:0] digit_10
);
    assign digit_1 = i_data % 10;
    assign digit_10 = i_data / 10 % 10;  
endmodule

module bcd_decoder_swt(
    input [3:0] bcd,
    output reg [7:0] fnd_data   // reg type
);
    always @(bcd) begin   // behavioral modeling : output of always phrase can be only reg type
        case (bcd)
            4'h0: fnd_data = 8'hc0;
            4'h1: fnd_data = 8'hf9;
            4'h2: fnd_data = 8'ha4;
            4'h3: fnd_data = 8'hb0;
            4'h4: fnd_data = 8'h99;
            4'h5: fnd_data = 8'h92;
            4'h6: fnd_data = 8'h82;
            4'h7: fnd_data = 8'hf8;  
            4'h8: fnd_data = 8'h80;
            4'h9: fnd_data = 8'h90;
            4'he: fnd_data = 8'hff;
            4'hf: fnd_data = 8'h7f;
            default: fnd_data = 8'hff;
        endcase
    end
endmodule

