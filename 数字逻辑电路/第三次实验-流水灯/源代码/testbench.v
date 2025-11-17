`timescale 1ns / 1ps
module testbench;
reg clk;   
reg rst;  //S1 复位按键
reg button;  //S2 流动按钮
reg [1:0] freq_set; // Sw1-0
reg dir_set;//Sw23 0向右移位 1向左移位
wire [7:0] led;    //GLD7-0
localparam test_1000hz = 26'd100-1; // 实际是 1000khz,1000ns
localparam test_500hz = 26'd1000-1; // 实际是 100khz,10000ns
localparam test_20hz = 26'd5000-1; // 实际是 20khz,50000ns
localparam test_5hz = 26'd20000-1; // 实际是 5khz,200000ns

initial 
begin
    rst = 1;
    button = 0;
    freq_set = 2'b00; //1000khz
    dir_set = 0; //右移

    #20
    rst=0;
    #10

    button=1; //启动流水灯
    #10
    button=0;
    #5000 //移动5格

    button=1; //暂停流水灯
    #10
    button=0;  
    #5000 //led不动

    /////////////////
    freq_set = 2'b01; //100khz
    #10
    button=1; //启动流水灯
    #10
    button=0;
    #30000 //移动3格
    /////////////////
    freq_set = 2'b00; 
    dir_set = 1; //测试左移
    #5000 
    button=1; //暂停流水灯
    #10
    button=0;  

    rst = 1; //复位
    #5000
    $finish;
end

initial 
begin
    clk = 0;
end
always #5 clk = ~clk; 

count #(
    .cnt_1000hz(test_1000hz),
    .cnt_500hz(test_500hz),
    .cnt_20hz(test_20hz),
    .cnt_5hz(test_5hz)
) u_count (
    .clk(clk),
    .rst(rst),
    .button(button),
    .freq_set(freq_set),
    .dir_set(dir_set),
    .led(led)
);
endmodule