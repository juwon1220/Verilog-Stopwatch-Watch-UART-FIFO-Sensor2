`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/18 14:20:27
// Design Name: 
// Module Name: fifo
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


module fifo(
    input        clk    ,
    input        rst    ,
    input  [7:0] w_data ,
    input        push   ,
    input        pop    ,
    output [7:0] r_data ,
    output       full   ,
    output       empty
);

    wire [1:0] w_addr_w, r_addr_w;

    register_file U_REG_FILE(
        .clk    (clk),
        .w_data (w_data),
        .w_addr (w_addr_w),
        .r_addr (r_addr_w),
        .wr_en  ((~full & push)),
        .r_data (r_data)
    );

    fifo_control_unit U_FIFO_CTRL_UNIT(
        .clk    (clk),
        .rst    (rst),
        .push   (push),
        .pop    (pop),
        .w_addr (w_addr_w),
        .r_addr (r_addr_w),
        .full   (full),
        .empty  (empty)
    );

endmodule

module register_file (
    input        clk    ,
    input  [7:0] w_data ,
    input  [1:0] w_addr ,
    input  [1:0] r_addr ,
    input        wr_en  ,
    output [7:0] r_data 
);

    reg [7:0] mem[0:3];

    // read mem
    assign r_data = mem[r_addr];

    always @(posedge clk) begin
        if (wr_en) begin
            // write to mem
            mem[w_addr] <= w_data;
        end
    end
endmodule

module fifo_control_unit (
    input        clk    ,
    input        rst    ,
    input        push   ,
    input        pop    ,
    output [1:0] w_addr ,
    output [1:0] r_addr ,
    output       full   ,
    output       empty
);

    // ptr & counter register
    reg [1:0] w_ptr_reg, w_ptr_next;
    reg [1:0] r_ptr_reg, r_ptr_next;
    reg [2:0] cnt_reg, cnt_next;

    assign w_addr = w_ptr_reg;
    assign r_addr = r_ptr_reg;
    assign full   = (cnt_reg == 4);
    assign empty  = (cnt_reg == 0);

    // SL
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            w_ptr_reg  <= 2'b00;
            r_ptr_reg  <= 2'b00;
            cnt_reg    <= 3'b000;
        end else begin
            w_ptr_reg  <= w_ptr_next;
            r_ptr_reg  <= r_ptr_next;
            cnt_reg    <= cnt_next;
        end
    end

    // CL
    always @(*) begin
        w_ptr_next  = w_ptr_reg;
        r_ptr_next  = r_ptr_reg;
        cnt_next    = cnt_reg;

        case ({push, pop})
            2'b01: begin // pop
                if (cnt_reg != 0) begin
                    r_ptr_next = r_ptr_reg + 1;
                    cnt_next   = cnt_reg - 1;
                end
            end
            2'b10: begin // push
                if (cnt_reg != 4) begin
                    w_ptr_next = w_ptr_reg + 1;
                    cnt_next   = cnt_reg + 1;
                end
            end
            2'b11: begin // push & pop
                if (cnt_reg != 0 && cnt_reg != 4) begin
                    w_ptr_next = w_ptr_reg + 1;
                    r_ptr_next = r_ptr_reg + 1;
                    cnt_next   = cnt_reg;
                end else if (cnt_reg == 0) begin // can't pop
                    w_ptr_next = w_ptr_reg + 1;
                    cnt_next   = cnt_reg + 1;
                end else if (cnt_reg == 4) begin // can't push
                    r_ptr_next = r_ptr_reg + 1;
                    cnt_next   = cnt_reg - 1;
                end
            end
        endcase
    end
endmodule

/*module fifo_control_unit (
    input        clk    ,
    input        rst    ,
    input        push   ,
    input        pop    ,
    output [1:0] w_addr ,
    output [1:0] r_addr ,
    output       full   ,
    output       empty
);

    // register
    reg [1:0] w_ptr_reg, w_ptr_next;
    reg [1:0] r_ptr_reg, r_ptr_next;
    reg full_reg, full_next;
    reg empty_reg, empty_next;

    // output
    assign w_addr = w_ptr_reg;
    assign r_addr = r_ptr_reg;
    assign full   = full_reg;
    assign empty  = empty_reg;

    // sequential logic
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            w_ptr_reg <= 2'b00;
            r_ptr_reg <= 2'b00;
            full_reg  <= 1'b0;
            empty_reg <= 1'b1;
        end else begin
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    // combinational logic
    always @(*) begin
        w_ptr_next = w_ptr_reg;
        r_ptr_next = r_ptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;

        case ({push, pop})
            2'b01: begin // pop
                if (!empty_reg) begin
                    r_ptr_next = r_ptr_reg + 1;
                    full_next  = 1'b0;
                    if (w_ptr_reg == r_ptr_reg) begin
                        empty_next = 1'b1;
                    end
                end
            end
            2'b10: begin // push
                if (!full_reg) begin
                    w_ptr_next = w_ptr_reg + 1;
                    empty_next = 1'b0;
                    if (w_ptr_next == r_ptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end
            2'b11: begin // push & pop
                if (empty_reg) begin
                    w_ptr_next = w_ptr_reg + 1;
                    empty_next = 1'b0;
                end else if (full_reg) begin
                    r_ptr_next = r_ptr_reg + 1;
                    full_next = 1'b0;
                end else begin
                    w_ptr_next = w_ptr_reg + 1;
                    r_ptr_next = r_ptr_reg + 1;
                end
            end
        endcase
    end
endmodule*/