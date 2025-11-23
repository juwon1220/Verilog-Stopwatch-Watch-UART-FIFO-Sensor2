`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/16 18:21:18
// Design Name: 
// Module Name: ascii_sender
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


module ascii_sender_watch (
    input        clk        ,
    input        rst        ,
    input        start      ,
    input        tx_busy    ,
    input  [7:0] time_data  ,
    output       send_start ,
    output [7:0] ascii_data 
);

    parameter IDLE = 0, SEND = 1;

    reg state;
    reg r_send;
    reg [5:0] send_cnt;
    reg [2:0] time_cnt, time_cnt_next;
    reg [7:0] r_ascii_data [0:18];
    reg [7:0] time_reg [0:7];

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            time_cnt <= 0;
            time_reg[0] <= 0;
            time_reg[1] <= 0;
            time_reg[2] <= 0;
            time_reg[3] <= 0;
            time_reg[4] <= 0;
            time_reg[5] <= 0;
            time_reg[6] <= 0;
            time_reg[7] <= 0;
        end else begin
            time_cnt <= time_cnt_next;
            time_reg[time_cnt] <= time_data;
        end
    end

    always @(*) begin
        if (time_cnt == 7) begin
            time_cnt_next = 0;
        end else begin
            time_cnt_next = time_cnt + 1;
        end
    end

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            state <= IDLE;
            r_send <= 0;
            send_cnt <= 0;
            r_ascii_data[0]  <= "T";
            r_ascii_data[1]  <= "I";
            r_ascii_data[2]  <= "M";
            r_ascii_data[3]  <= "E";
            r_ascii_data[4]  <= " ";
            r_ascii_data[5]  <= "=";
            r_ascii_data[6]  <= " ";
            r_ascii_data[9]  <= ":";
            r_ascii_data[12]  <= ":";
            r_ascii_data[15]  <= ":";
            r_ascii_data[18] <= "\n";
        end 
        else begin
            r_ascii_data[7]  <= time_reg[7];
            r_ascii_data[8]  <= time_reg[6];
            r_ascii_data[10]  <= time_reg[5];
            r_ascii_data[11]  <= time_reg[4];
            r_ascii_data[13]  <= time_reg[3];
            r_ascii_data[14]  <= time_reg[2];
            r_ascii_data[16]  <= time_reg[1];
            r_ascii_data[17] <= time_reg[0];
            case (state)
                IDLE: begin
                    send_cnt <= 0;
                    r_send <= 0;
                    if (start) begin
                        state <= SEND;
                        r_send <= 1;
                    end
                end
                SEND: begin
                    r_send <= 1'b0;
                    if(!tx_busy && !r_send) begin
                        r_send <= 1;
                        if (send_cnt == 18) begin
                            r_send <= 1'b0;
                            state <= IDLE;
                        end else begin
                            send_cnt <= send_cnt + 1;
                            state <= SEND;
                        end
                    end 
                end
            endcase
        end
    end

    assign ascii_data = r_ascii_data[send_cnt];
    assign send_start = r_send;
endmodule




module ascii_sender_stopwatch (
    input        clk        ,
    input        rst        ,
    input        start      ,
    input        tx_busy    ,
    input  [7:0] time_data  ,
    output       send_start ,
    output [7:0] ascii_data 
);

    parameter IDLE = 0, SEND = 1;

    reg state;
    reg r_send;
    reg [5:0] send_cnt;
    reg [2:0] time_cnt, time_cnt_next;
    reg [7:0] r_ascii_data [0:23];
    reg [7:0] time_reg [0:7];

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            time_cnt <= 0;
            time_reg[0] <= 0;
            time_reg[1] <= 0;
            time_reg[2] <= 0;
            time_reg[3] <= 0;
            time_reg[4] <= 0;
            time_reg[5] <= 0;
            time_reg[6] <= 0;
            time_reg[7] <= 0;
        end else begin
            time_cnt <= time_cnt_next;
            time_reg[time_cnt] <= time_data;
        end
    end

    always @(*) begin
        if (time_cnt == 7) begin
            time_cnt_next = 0;
        end else begin
            time_cnt_next = time_cnt + 1;
        end
    end

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            state <= IDLE;
            r_send <= 0;
            send_cnt <= 0;
            r_ascii_data[0]  <= "S";
            r_ascii_data[1]  <= "T";
            r_ascii_data[2]  <= "O";
            r_ascii_data[3]  <= "P";
            r_ascii_data[4]  <= "W";
            r_ascii_data[5]  <= "A";
            r_ascii_data[6]  <= "T";
            r_ascii_data[7]  <= "C";
            r_ascii_data[8]  <= "H";
            r_ascii_data[9]  <= " ";
            r_ascii_data[10]  <= "=";
            r_ascii_data[11]  <= " ";
            r_ascii_data[14]  <= ":";
            r_ascii_data[17]  <= ":";
            r_ascii_data[20]  <= ":";
            r_ascii_data[23] <= "\n";
        end 
        else begin
            r_ascii_data[12]  <= time_reg[7];
            r_ascii_data[13]  <= time_reg[6];
            r_ascii_data[15]  <= time_reg[5];
            r_ascii_data[16]  <= time_reg[4];
            r_ascii_data[18]  <= time_reg[3];
            r_ascii_data[19]  <= time_reg[2];
            r_ascii_data[21]  <= time_reg[1];
            r_ascii_data[22] <= time_reg[0];
            case (state)
                IDLE: begin
                    send_cnt <= 0;
                    r_send <= 0;
                    if (start) begin
                        state <= SEND;
                        r_send <= 1;
                    end
                end
                SEND: begin
                    r_send <= 1'b0;
                    if(!tx_busy && !r_send) begin
                        r_send <= 1;
                        if (send_cnt == 23) begin
                            r_send <= 1'b0;
                            state <= IDLE;
                        end else begin
                            send_cnt <= send_cnt + 1;
                            state <= SEND;
                        end
                    end 
                end
            endcase
        end
    end

    assign ascii_data = r_ascii_data[send_cnt];
    assign send_start = r_send;
endmodule


module ascii_sender_timer (
    input        clk        ,
    input        rst        ,
    input        start      ,
    input        tx_busy    ,
    input  [7:0] time_data  ,
    output       send_start ,
    output [7:0] ascii_data 
);

    parameter IDLE = 0, SEND = 1;

    reg state;
    reg r_send;
    reg [5:0] send_cnt;
    reg [2:0] time_cnt, time_cnt_next;
    reg [7:0] r_ascii_data [0:19];
    reg [7:0] time_reg [0:7];

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            time_cnt <= 0;
            time_reg[0] <= 0;
            time_reg[1] <= 0;
            time_reg[2] <= 0;
            time_reg[3] <= 0;
            time_reg[4] <= 0;
            time_reg[5] <= 0;
            time_reg[6] <= 0;
            time_reg[7] <= 0;
        end else begin
            time_cnt <= time_cnt_next;
            time_reg[time_cnt] <= time_data;
        end
    end

    always @(*) begin
        if (time_cnt == 7) begin
            time_cnt_next = 0;
        end else begin
            time_cnt_next = time_cnt + 1;
        end
    end

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            state <= IDLE;
            r_send <= 0;
            send_cnt <= 0;
            r_ascii_data[0]  <= "T";
            r_ascii_data[1]  <= "I";
            r_ascii_data[2]  <= "M";
            r_ascii_data[3]  <= "E";
            r_ascii_data[4]  <= "R";
            r_ascii_data[5]  <= " ";
            r_ascii_data[6]  <= "=";
            r_ascii_data[7]  <= " ";
            r_ascii_data[10]  <= ":";
            r_ascii_data[13]  <= ":";
            r_ascii_data[16]  <= ":";
            r_ascii_data[19] <= "\n";
        end 
        else begin
            r_ascii_data[8]  <= time_reg[7];
            r_ascii_data[9]  <= time_reg[6];
            r_ascii_data[11]  <= time_reg[5];
            r_ascii_data[12]  <= time_reg[4];
            r_ascii_data[14]  <= time_reg[3];
            r_ascii_data[15]  <= time_reg[2];
            r_ascii_data[17]  <= time_reg[1];
            r_ascii_data[18] <= time_reg[0];
            case (state)
                IDLE: begin
                    send_cnt <= 0;
                    r_send <= 0;
                    if (start) begin
                        state <= SEND;
                        r_send <= 1;
                    end
                end
                SEND: begin
                    r_send <= 1'b0;
                    if(!tx_busy && !r_send) begin
                        r_send <= 1;
                        if (send_cnt == 19) begin
                            r_send <= 1'b0;
                            state <= IDLE;
                        end else begin
                            send_cnt <= send_cnt + 1;
                            state <= SEND;
                        end
                    end 
                end
            endcase
        end
    end

    assign ascii_data = r_ascii_data[send_cnt];
    assign send_start = r_send;
endmodule



module ascii_sender_DHT11 (
    input        clk        ,
    input        rst        ,
    input        start      ,
    input        tx_busy    ,
    //input  [7:0] time_data,
    input  [7:0] humid_temp,
    // input  [3:0] humid  ,
    // input  [3:0] temp,
    output       send_start ,
    output [7:0] ascii_data 
);

    parameter IDLE = 0, SEND = 1;

    reg state;
    reg r_send;
    reg [5:0] send_cnt;
    reg [2:0] time_cnt, time_cnt_next;
    reg [7:0] r_ascii_data [0:24];
    // reg [3:0] humid_reg [0:7];
    // reg [3:0] temp_reg [0:7];
    reg [7:0] humid_temp_reg [0:7];
    //reg [7:0] time_reg [0:7];
    
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            time_cnt <= 0;
            humid_temp_reg[0] <= 0;
            humid_temp_reg[1] <= 0;
            humid_temp_reg[2] <= 0;
            humid_temp_reg[3] <= 0;
            humid_temp_reg[4] <= 0;
            humid_temp_reg[5] <= 0;
            humid_temp_reg[6] <= 0;
            humid_temp_reg[7] <= 0;
        end else begin
            time_cnt <= time_cnt_next;
            humid_temp_reg[time_cnt] <= humid_temp;
        end
    end

    always @(*) begin
        if (time_cnt == 7) begin
            time_cnt_next = 0;
        end else begin
            time_cnt_next = time_cnt + 1;
        end
    end

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            state <= IDLE;
            r_send <= 0;
            send_cnt <= 0;
            r_ascii_data[0]  <= "H";
            r_ascii_data[1]  <= "U";
            r_ascii_data[2]  <= "M";
            r_ascii_data[3]  <= "I";
            r_ascii_data[4]  <= "D";

            r_ascii_data[5]  <= " ";
            r_ascii_data[6]  <= "=";
            r_ascii_data[7]  <= " ";
            r_ascii_data[11]  <= ",";
            r_ascii_data[12]  <= " ";
            r_ascii_data[13]  <= "T";
            r_ascii_data[14]  <= "E";
            r_ascii_data[15]  <= "M";
            r_ascii_data[16]  <= "P";
            r_ascii_data[17]  <= " ";
            r_ascii_data[18]  <= "=";
            r_ascii_data[19]  <= " ";
            r_ascii_data[24] <= "\n";
        end 
        else begin
            r_ascii_data[7]  <=  humid_temp_reg[7];
            r_ascii_data[8]  <=  humid_temp_reg[6];
            r_ascii_data[9]  <= humid_temp_reg[5];
            r_ascii_data[10]  <= humid_temp_reg[4];
            r_ascii_data[20]  <= humid_temp_reg[3];
            r_ascii_data[21]  <= humid_temp_reg[2];
            r_ascii_data[22]  <= humid_temp_reg[1];
            r_ascii_data[23] <=  humid_temp_reg[0];
            case (state)
                IDLE: begin
                    send_cnt <= 0;
                    r_send <= 0;
                    if (start) begin
                        state <= SEND;
                        r_send <= 1;
                    end
                end
                SEND: begin
                    r_send <= 1'b0;
                    if(!tx_busy && !r_send) begin
                        r_send <= 1;
                        if (send_cnt == 24) begin
                            r_send <= 1'b0;
                            state <= IDLE;
                        end else begin
                            send_cnt <= send_cnt + 1;
                            state <= SEND;
                        end
                    end 
                end
            endcase
        end
    end

    assign ascii_data = r_ascii_data[send_cnt];
    assign send_start = r_send;
endmodule

module ascii_sender_SR04 (
    input        clk,
    input        rst,
    input        start,
    input        tx_busy,
    input  [7:0] sr04_data,
    output       send_start,
    output [7:0] ascii_data
);

    parameter IDLE = 0, SEND = 1;


    reg [4:0] send_cnt;
    reg [1:0] c_dist_cnt, n_dist_cnt;
    reg r_send;
    reg state;
    reg [7:0] r_ascii_data[0:18];
    reg [7:0] r_dist[0:3];

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_dist_cnt <= 0;
            r_dist[0]  <= 0;
            r_dist[1]  <= 0;
            r_dist[2]  <= 0;
            r_dist[3]  <= 0;
        end else begin
            c_dist_cnt <= n_dist_cnt;
            r_dist[c_dist_cnt] <= sr04_data;
        end
    end

    always @(*) begin
        if (c_dist_cnt == 3) begin
            n_dist_cnt = 0;
        end else begin
            n_dist_cnt = c_dist_cnt + 1;
        end
    end


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= IDLE;
            send_cnt <= 0;
            r_send <= 0;
            r_ascii_data[0] <= "D";
            r_ascii_data[1] <= "I";
            r_ascii_data[2] <= "S";
            r_ascii_data[3] <= "T";
            r_ascii_data[4] <= "A";
            r_ascii_data[5] <= "N";
            r_ascii_data[6] <= "C";
            r_ascii_data[7] <= "E";
            r_ascii_data[8] <= " ";
            r_ascii_data[9] <= "=";
            r_ascii_data[10] <= " ";
            r_ascii_data [14] <= ".";
            r_ascii_data[16] <= "c";
            r_ascii_data[17] <= "m";
            r_ascii_data[18] <= "\n";
        end else begin
            r_ascii_data[11] <= r_dist[3]; 
            r_ascii_data[12] <= r_dist[2]; 
            r_ascii_data[13] <= r_dist[1]; 
            r_ascii_data[15] <= r_dist[0]; 
            case (state)
                IDLE: begin
                    send_cnt <= 0;
                    r_send   <= 1'b0;
                    if (start) begin
                        state  <= SEND;
                        r_send <= 1'b1;
                    end
                end
                SEND: begin
                    r_send <= 1'b0;  //1 tick gen
                    if (!tx_busy && !r_send) begin
                        r_send   <= 1'b1;
                        if (send_cnt == 18) begin
                            state  <= IDLE;
                            r_send <= 1'b0;
                        end else begin
                            state <= SEND;
                            send_cnt <= send_cnt + 1;
                        end
                    end
                end
            endcase
        end
    end

    assign send_start = r_send;
    assign ascii_data = r_ascii_data[send_cnt];

endmodule