module led_ctrl_unit (
    input wire rst,
    input wire clk,
    input wire [31:0] display, // {DK7, DK6, ..., DK0}
    output reg [7:0] led_en, // 阳极 A[7:0], 低电平有效
    output reg [7:0] led_cx  // 段选 {CA..CG,DP}, 低电平有效
);

    // 1ms 刷新率 @ 100MHz (100_000 cycles)
    localparam REFRESH_COUNT = 100_000 - 1; // 用于上板
    // localparam REFRESH_COUNT = 100 - 1;     // 用于仿真
    reg [16:0] refresh_counter; // 2^17 > 100k
    reg [2:0] anode_sel; // 0 to 7

    // 刷新计数器和阳极选择
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            refresh_counter <= 0;
            anode_sel <= 3'd0;
        end else begin
            if (refresh_counter == REFRESH_COUNT) begin
                refresh_counter <= 0;
                anode_sel <= anode_sel + 1; // 切换到下一个数码管
            end else begin
                refresh_counter <= refresh_counter + 1;
            end
        end
    end

    // 阳极使能 (led_en), 低电平有效
    // A[7] -> DK7 (最左), A[0] -> DK0 (最右)
    always @(*) begin
        case (anode_sel)
            3'd0: led_en = 8'b11111110; // 选 DK0
            3'd1: led_en = 8'b11111101; // 选 DK1
            3'd2: led_en = 8'b11111011; // 选 DK2
            3'd3: led_en = 8'b11110111; // 选 DK3
            3'd4: led_en = 8'b11101111; // 选 DK4
            3'd5: led_en = 8'b11011111; // 选 DK5
            3'd6: led_en = 8'b10111111; // 选 DK6
            3'd7: led_en = 8'b01111111; // 选 DK7
            default: led_en = 8'b11111111; // 全灭
        endcase
    end

    // 数据选择器 (Mux)
    wire [3:0] data_for_digit;
    assign data_for_digit = (anode_sel == 3'd0) ? display[ 3: 0] : // DK0
                            (anode_sel == 3'd1) ? display[ 7: 4] : // DK1
                            (anode_sel == 3'd2) ? display[11: 8] : // DK2
                            (anode_sel == 3'd3) ? display[15:12] : // DK3
                            (anode_sel == 3'd4) ? display[19:16] : // DK4
                            (anode_sel == 3'd5) ? display[23:20] : // DK5
                            (anode_sel == 3'd6) ? display[27:24] : // DK6
                                                  display[31:28];  // DK7

    // BCD 到 7段码 译码器 (共阳极, 低电平有效)
    // led_cx = {CA, CB, CC, CD, CE, CF, CG, DP} (DP默认熄灭=1)
    always @(*) begin
        case (data_for_digit)
            4'h0: led_cx = 8'h03;
            4'h1: led_cx = 8'h9F;
            4'h2: led_cx = 8'h25; 
            4'h3: led_cx = 8'h0D; 
            4'h4: led_cx = 8'h99; 
            4'h5: led_cx = 8'h49;
            4'h6: led_cx = 8'h41; 
            4'h7: led_cx = 8'h1F; 
            4'h8: led_cx = 8'h01; 
            4'h9: led_cx = 8'h09; 
            4'hA: led_cx = 8'h11; 
            4'hB: led_cx = 8'hC1; 
            4'hC: led_cx = 8'h63; 
            4'hD: led_cx = 8'h85; 
            4'hE: led_cx = 8'h61; 
            4'hF: led_cx = 8'h71; 
            default: led_cx = 8'hFF; // 熄灭
        endcase
    end
endmodule