`timescale 1ns / 1ps
module tb_top;
  reg clk;
  reg S1;       // 复位
  reg S2;       // 启停
  reg S3;       // 计数
  reg SW0;      // 总开关

  // 对应 top 模块的 output
  wire [7:0] led_en;
  wire [7:0] led_cx;

  // 观测数码管显示的数据
  wire [31:0] data_display;
  assign data_display = u_top.display;

  // 例化
  top #(
        .clock_max(1000 - 1),  // 10us 30次计数器周期
        .cnt_max(1000 ),   // 10us 消抖时间
        .time_max(100-1)   // 1us 刷新时间
      )u_top (
        .clk(clk),
        .S1(S1),
        .S2(S2),
        .S3(S3),
        .SW0(SW0),
        .led_en(led_en),
        .led_cx(led_cx)
      );

  initial
    begin
      clk = 0;
    end
  always #5 clk = ~clk;

  initial
    begin
      S1 = 1;
      S2 = 0;
      S3 = 0;
      SW0 = 0; // 初始状态
      #10;

      S1=0;
      #10;
      // 内部所有计数器都应为 0

      SW0 = 1; // 开启总开关

      // *** 重要提示: 见下方说明 (1) ***
      // 0.1s = 100,000,000 ns. 仿真会很慢.
      // 等待 3.5 个 0.1s 周期, 观察 DK1-DK0
      #(10000); // 10us 后, data_display[7:0] 应为 8'h01
      #(10000); // 20us 后, data_display[7:0] 应为 8'h02
      #(10000); // 30us 后, data_display[7:0] 应为 8'h03

      // S2 暂停
      S2 = 1;
      #(10000+1000);
      S2 = 0;

      // 等待 2us, 计数值 应该保持在 8'h03 不变
      #(20000);

      S2 = 1;
      #1000;
      S2 = 0; // 再次按键, 模拟毛刺

      #(10000); // 10us 后, 计数值依旧不变


      // 测试按键计数功能
      S3 = 1;
      #10;
      S3 = 0; // 模拟毛刺
      #10000;

      S3 = 1;
      #10;
      S3 = 0; // 模拟毛刺
      #10000;

      S3 = 1;
      #10;
      S3 = 0; // 模拟毛刺
      #10000;

      
      S3 = 1; // 测试消抖
      #(10000+1000); // 10us 消抖时间
      S3 = 0; // 释放按键
      #(10000+1000);

      S3 = 1; 
      #(10000+1000); 
      S3 = 0; 
      #(10000+1000);

      // 此时消抖计数应该只计算了两次

      // (5) 测试 SW0 关闭显示
      SW0 = 0;
      #10000; // 等待 10us，显示全灭
      $finish; 
    end

endmodule
