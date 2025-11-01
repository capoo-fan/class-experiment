module count 
#(
    //参数例化
    parameter cnt_1000hz=26'd1_00_000-1, //1000hz计数最大值
    parameter cnt_500hz=26'd1_000_000-1,   //100hz计数最大值
    parameter cnt_20hz=26'd5_000_000-1, //20hz计数最大值
    parameter cnt_5hz=26'd20_000_000-1   //5hz计数最大值
)
(
    input  wire clk,   
    input  wire rst,  //S1 复位按键
    input  wire button,  //S2 流动按钮
    input  wire [1:0] freq_set, // Sw1-0
    input  wire dir_set, //Sw23 0向右移位 1向左移位
    output reg  [7:0] led    //GLD7-0
   
);

//边沿检测
reg sig_r0,sig_r1,sig_r2;
always @(posedge clk or posedge rst) 
begin
    if (rst)
        sig_r0 <= 1'b0;
    else
        sig_r0 <= button;
end
always @(posedge clk or posedge rst) 
begin
    if (rst)
    begin
        sig_r1 <= 1'b0;
        sig_r2 <= 1'b0;
    end
    else
    begin
        sig_r1 <= sig_r0;
        sig_r2 <= sig_r1;
    end
end
assign pos_edge = ~sig_r2 & sig_r1;

// 控制启停
reg flag; 
always @(posedge clk or posedge rst)
begin
    if (rst)
        flag <= 1'b0;
    else if (pos_edge)
        flag <= ~flag;
end

// freq_set 控制
reg [25:0] cnt_max;
always @(*) 
begin
        case (freq_set)
            2'b00: cnt_max = cnt_1000hz; //1000hz
            2'b01: cnt_max = cnt_500hz; //100hz
            2'b10: cnt_max = cnt_20hz;  //20hz
            2'b11: cnt_max = cnt_5hz;  //5hz
            default : cnt_max = 26'd0;
        endcase
end

//计数器的实现
reg [25:0] cnt;
wire cnt_inc;
assign cnt_inc =flag;
wire cnt_end = cnt_inc & (cnt >= cnt_max);
always @(posedge clk or posedge rst) 
begin
    if(rst)
       cnt <= 26'd0;
    else if(cnt_end)
       cnt <= 26'd0;
    else if(cnt_inc)
       cnt <= cnt + 26'd1;
end

// 流水灯实现
always @(posedge clk or posedge rst) 
begin
    if(rst)
    begin
       led <= 8'h01;
    end  
    else if(cnt_end)
    begin
        if(dir_set==1'b0) //右移
        begin
            led<={led[0],led[7:1]};
        end
        else //左移
        begin
            led<={led[6:0],led[7]};
        end
    end
end
endmodule
