module top (
    input wire clk,        // 100MHz 时钟
    input wire S1,          // 异步复位
    input wire S3,          // 发送按键
    input wire uart_rx,    // UART 接收
    input wire SW0,        // 开关 SW0,string_match 和发送学号的切换信号
    output wire uart_tx,   // UART 发送
    output wire [7:0] led_en,  // 数码管位选
    output wire [7:0] led_cx   // 数码管段选
  );

  wire rst = S1;

  // S3
  wire s3_debounced;
  wire s3_posedge;

  // UART 接收
  wire recv_valid;
  wire [7:0] recv_data;

  // 数码管显示
  wire [39:0] display_data; // 连接到 led_ctrl_unit 的数据


  wire s3_mode_tx;      //send mode
  wire match_mode_tx; //string match mode

  assign uart_tx = (SW0 == 1'b0) ? s3_mode_tx : match_mode_tx;

  // 按键 S3 消抖
  debounce #(
             .cnt_max(2_000_000)
           ) u_debounce_s3 (
             .clk(clk),
             .rst(rst),
             .button_in(S3),
             .button_out(s3_debounced)
           );

  // S3 上升沿检测
  edge_detect u_edge_detect_s3 (
                .clk(clk),
                .rst(rst),
                .signal(s3_debounced),
                .pos_edge(s3_posedge)
              );

  // UART 接收
  uart_recv u_uart_recv (
              .clk(clk),
              .rst(rst),
              .din(uart_rx),
              .valid(recv_valid),
              .data(recv_data)
            );

  // UART 接收数据显示逻辑
  // 负责处理接收到的数据并生成39位显示总线
  display_logic u_display_logic (
                  .clk(clk),
                  .rst(rst),
                  .valid(recv_valid),
                  .recv_data(recv_data),
                  .display_data(display_data) // 输出到 led_ctrl
                );

  // 8 位数码管驱动
  led_ctrl_unit #(
                  .time_max(100_000 - 1) // 1ms 刷新率
                ) u_led_ctrl (
                  .rst(rst),
                  .clk(clk),
                  .display(display_data), // 连接到 display_logic 的输出
                  .led_en(led_en),
                  .led_cx(led_cx)
                );

  send_ctrl u_send_ctrl (
              .clk(clk),
              .rst(rst),
              .s3(s3_posedge),
              .uart_tx(s3_mode_tx)
            );

  string_match u_string_match (
                 .clk(clk),
                 .rst(rst),
                  .valid(recv_valid),
                 .recv_data(recv_data),
                 .uart_tx(match_mode_tx)
               );

endmodule
