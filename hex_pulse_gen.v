`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/21 17:01:27
// Design Name: 
// Module Name: hex_pulse_gen
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


/*module hex_pulse_gen #(parameter HEX = 8'h30, parameter DIV = 2000)(
    input       clk      ,
    input       rst      ,
    input [7:0] rx_data  ,
    input       tx_empty ,
    output      p_out    
    );

    localparam p_cycle = (100_000_000) / DIV;

    wire [7:0] w_rx_data;

    reg [$clog2(p_cycle) - 1:0] p_count_reg, p_count_next;
    reg p_enable_reg, p_enable_next;
    reg p_out_reg, p_out_next;
    assign p_out = p_out_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            p_count_reg <= 0;
            p_enable_reg <= 0;
            p_out_reg <= 0;
        end else begin
            p_count_reg <= p_count_next;
            p_enable_reg <= p_enable_next;
            p_out_reg <= p_out_next;
        end
    end

    always @(*) begin
        p_count_next  = p_count_reg;
        p_enable_next = p_enable_reg;
        p_out_next    = p_out_reg;

        if(~tx_empty && rx_data == HEX) begin
            p_count_next  = 0;
            p_enable_next = 1;
            p_out_next = 1;
        end 
        
        if (p_enable_reg == 1) begin
            if(p_count_reg == (p_cycle) - 1) begin
                p_enable_next = 0;
                p_count_next = 0;
                p_out_next = 0;
            end else begin
                p_count_next = p_count_reg + 1;
                p_out_next = 1;
            end
        end
    end
endmodule*/

module hex_pulse_gen#(parameter DIV = 2000)(
    input        clk      ,
    input        rst      ,
    input  [7:0] rx_data  ,
    input        tx_empty ,
    output [7:0] p_out     
);

    // 1ms = 1_000_000ns / 10ns (100MHz) = 100,000 사이클
    localparam p_cycle = 100_000_000 / DIV;

    reg [$clog2(p_cycle):0] p_count;
    reg        p_enable;
    reg [7:0]  p_out_reg;

    assign p_out = p_out_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            p_count    <= 0;
            p_enable   <= 0;
            p_out_reg  <= 0;
        end else begin
            if (~tx_empty) begin
                p_out_reg  <= rx_data;
                p_count    <= 0;
                p_enable   <= 1;
            end else if (p_enable) begin
                if (p_count < p_cycle) begin
                    p_count <= p_count + 1;
                end else begin
                    p_enable   <= 0;
                    p_out_reg  <= 0;
                end
            end else begin
                p_out_reg <= 0;
            end
        end
    end

endmodule