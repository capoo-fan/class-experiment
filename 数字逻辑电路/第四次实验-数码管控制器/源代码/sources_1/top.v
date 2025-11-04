module top #(
    parameter clock_max = 24'd10_000_000 - 1,  // 0.1s
    parameter cnt_max = 2_000_000 ,   // 20ms
    parameter time_max = 100_000 - 1   // 1ms
  )(
    input wire clk,
    input wire S1,       // 复位
    input wire S2,       // 计数器开关
    input wire S3,       // +1 按键
    input wire SW0,      // 总开关
    output wire [7:0] led_en,    // 位选信号
    output wire [7:0] led_cx   // 段选信号
  );
  wire rst = S1;

  wire [31:0] display;
  wire [7:0]  anode_out;
  wire [7:0]  segment_out;

  // 未消抖
  wire s3_edge;
  reg  [3:0] cnt_nd_ones, cnt_nd_tens;

  // 消抖计数器
  wire s3_db, s3_db_edge;
  reg  [3:0] cnt_d_ones, cnt_d_tens; // BCD 计数

  // 时间计数器
  wire s2_db, s2_edge;
  wire clk_10hz;
  reg  pause;
  reg  [3:0] cnt_ones, cnt_tens;


  wire [3:0] dig7, dig6; //学号
  wire [3:0] dig5, dig4; //未消抖计数
  wire [3:0] dig3, dig2; //消抖计数
  wire [3:0] dig1, dig0; //计数器

  // 学号
  assign dig7 = 4'd4;
  assign dig6 = 4'd8;


  // 未消抖计数
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        begin
          cnt_nd_ones <= 4'd0;
          cnt_nd_tens <= 4'd0;
        end
      else if (s3_edge)
        begin
          if (cnt_nd_ones == 4'd9)  //处理进位
            begin
              cnt_nd_ones <= 4'd0;
              cnt_nd_tens <= cnt_nd_tens + 1;
            end
          else
            begin
              cnt_nd_ones <= cnt_nd_ones + 1;
            end
        end
    end
  assign dig5 = cnt_nd_tens;
  assign dig4 = cnt_nd_ones;


  // 消抖计数
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        begin
          cnt_d_ones <= 4'd0;
          cnt_d_tens <= 4'd0;
        end
      else if (s3_db_edge)
        begin
          if (cnt_d_ones == 4'd9)
            begin
              cnt_d_ones <= 4'd0;
              cnt_d_tens <= cnt_d_tens + 1;
            end
          else
            begin
              cnt_d_ones <= cnt_d_ones + 1;
            end
        end
    end
  assign dig3 = cnt_d_tens;
  assign dig2 = cnt_d_ones;


  //时间计数器
  reg [23:0] clock;
  assign clk_10hz = (clock == clock_max);
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        clock <= 24'd0;
      else if (clock == clock_max)
        clock <= 24'd0;
      else
        clock <= clock + 1;
    end
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        pause <= 1'b0;
      else if (s2_edge)
        pause <= ~pause; //S2 启停
    end

  wire flag = clk_10hz && !pause;
  always @(posedge clk or posedge rst) //+1逻辑的实现
    begin
      if (rst)
        begin
          cnt_tens <= 4'd0;
          cnt_ones <= 4'd0;
        end
      else if (flag)
        begin
          if (cnt_tens == 4'd3 && cnt_ones == 4'd0)
            begin
              cnt_tens <= 4'd0;
              cnt_ones <= 4'd0;
            end
          else if (cnt_ones == 4'd9)
            begin
              cnt_ones <= 4'd0;
              cnt_tens <= cnt_tens + 1;
            end
          else
            begin
              cnt_ones <= cnt_ones + 1;
            end
        end
    end
  assign dig1 = cnt_tens;
  assign dig0 = cnt_ones;

  // 输出
  assign display = {dig7, dig6, dig5, dig4, dig3, dig2, dig1, dig0};
  assign led_en = (SW0) ? anode_out : 8'b1111_1111;
  assign led_cx = (SW0) ? segment_out : 8'b1111_1111;

  // 数码管显示控制模块
  led_ctrl_unit #(
                  .time_max(time_max)
                )u_led_ctrl
                (
                  .rst(rst),
                  .clk(clk),
                  .display(display),
                  .led_en(anode_out),
                  .led_cx(segment_out)
                );
  // 消抖模块
  debounce #(
             .cnt_max(cnt_max)
           )u_debounce_s2 ( .clk(clk), .rst(rst), .button_in(S2), .button_out(s2_db) );
  debounce #(
             .cnt_max(cnt_max)
           )u_debounce_s3 ( .clk(clk), .rst(rst), .button_in(S3), .button_out(s3_db) );
  // 边沿检测模块
  edge_detect u_edge_s2 ( .clk(clk), .rst(rst), .signal(s2_db), .pos_edge(s2_edge) );
  edge_detect u_edge_s3 ( .clk(clk), .rst(rst), .signal(S3), .pos_edge(s3_edge) );
  edge_detect u_edge_s3_db( .clk(clk), .rst(rst), .signal(s3_db), .pos_edge(s3_db_edge) );
endmodule
