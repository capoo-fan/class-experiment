`timescale 1ns/1ps

module send_ctrl_tb();
  localparam CLK_FREQ = 100_000_000;          // clock frequency: 100 MHz
  localparam PERIOD   = 1e9/CLK_FREQ;         // clock cycle: 10ns
  localparam BAUD_RATE = 9600;
  localparam DIVIDER = CLK_FREQ / BAUD_RATE;  // clocks for one bit, should be 10416
  reg clk;
  reg rst;
  reg s3;         //  S3 按键信号
  wire uart_tx;   // DUT 的 UART 发送输出


  send_ctrl u_send_ctrl (
              .clk(clk),
              .rst(rst),
              .s3(s3),
              .uart_tx(uart_tx)
            );

  always #(PERIOD/2) clk = ~clk;

  initial
    begin
      clk = 0;
      rst = 1;
      s3 = 0;
      #(10*PERIOD) rst = 0;
      #(10*PERIOD);
      s3 = 1; // 按下 S3 按键
      #(PERIOD);
      s3 = 0; // 释放 S3 按键
      #(20_000_000);  // 等待 20ms
      $finish;
    end
endmodule
