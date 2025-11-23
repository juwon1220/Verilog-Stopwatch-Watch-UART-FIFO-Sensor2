`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/08 16:37:51
// Design Name: 
// Module Name: btn_debouncer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module btn_debouncer(
    input clk,
    input rst,
    input i_btn,
    output o_btn
);

    reg [3:0] q_reg, q_next;
    wire debounce;

    // clk divider 1Mhz
    reg [$clog2(10000)-1:0] counter;
    reg r_db_clk;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            counter <= 0;
            r_db_clk <= 0;
        end else begin
            if (counter == (10000-1)) begin
                counter <= 0;
                r_db_clk <= 1'b1;
            end else begin
                counter <= counter + 1;
                r_db_clk <= 1'b0;
            end
        end
    end

    // shift register
    always @(posedge r_db_clk, posedge rst) begin
        if(rst) begin
            q_reg <= 1'b0;
        end else begin
            q_reg <= q_next;
        end
    end

    // shift register
    always @(*) begin
        q_next = {i_btn, q_reg[3:1]};
    end

    // 4-input AND logic
    assign debounce = &(q_reg);

    reg edge_reg;

    // shift register (edge detection)
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end

    // rising edge detection
    assign o_btn = ~(edge_reg) & debounce;

    // falling edge detection
    // assign o_btn = ~(debounce) & edge_reg;
endmodule
