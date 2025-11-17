module uart_recv (
    input       wire       clk,        // 100MHz 系统时钟
    input       wire       rst,        // 异步复位
    input       wire       din,        // UART 接收数据
    output      reg        valid,      // 接收完成
    output      reg  [7:0] data      // 接收数据
  );
  localparam clk_freq = 100_000_000;  // 100MHz
  localparam baud_rate = 9600;
  localparam cyc_bit = clk_freq / baud_rate; // 10416
  localparam cyc_bit_half = (cyc_bit / 2) - 1; // 采样点,抗毛刺

  // FSM 状态定义
  localparam [1:0] IDLE = 2'b00;
  localparam [1:0] START = 2'b01;
  localparam [1:0] RECV = 2'b10;
  localparam [1:0] STOP = 2'b11;

  reg [15:0] cyc_cnt;   // 波特率计数器
  reg [2:0] bit_cnt;    // 接收到是第几位数据
  reg [7:0] data_reg; // 数据缓冲

  wire cyc_flag = (cyc_cnt == cyc_bit - 1);  // 比特周期
  wire cyc_half = (cyc_cnt == cyc_bit_half); //判断毛刺
  wire bit_flag = (bit_cnt == 3'd7); // 发送数据完毕

  // 状态转移
  reg [1:0] current_state, next_state;
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        begin
          current_state <= IDLE;
        end
      else
        begin
          current_state <= next_state;
        end
    end
  always @(*)
    begin
      case (current_state)
        IDLE:
          begin
            if (din == 1'b0)
              next_state = START; // 检测到起始位
            else
              next_state = IDLE;
          end
        START:
          begin
            if (cyc_half)  // 采样点
              begin
                if (din == 1'b0)
                  next_state = RECV;  // 起始位
                else
                  next_state = IDLE;  // 毛刺
              end
            else
              begin
                next_state = START;
              end
          end
        RECV:
          begin
            if (cyc_flag)
              begin
                if (bit_flag)
                  next_state = STOP;   // 8 位数据接收完毕
                else
                  next_state = RECV;   // 继续接收下一位
              end
            else
              begin
                next_state = RECV;
              end
          end
        STOP:
          begin
            if (cyc_flag)
              next_state = IDLE;   // 停止位接收完毕
            else
              next_state = STOP;
          end
        default:
          begin
            next_state = IDLE;
          end
      endcase
    end

  // 周期计数器
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        begin
          cyc_cnt <= 16'd0;
        end
      else if ((current_state == IDLE) ||
               (current_state == START && cyc_half) ||
               (current_state == RECV  && cyc_flag) ||
               (current_state == STOP  && cyc_flag))
        begin
          cyc_cnt <= 16'd0;
        end
      else if ((current_state == START) ||
               (current_state == RECV) ||
               (current_state == STOP))
        begin
          cyc_cnt <= cyc_cnt + 1;
        end
    end

  // 位计数器
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        begin
          bit_cnt <= 3'd0;
        end
      else if (current_state == IDLE)
        begin
          bit_cnt <= 3'd0;
        end
      else if (current_state == RECV && cyc_flag && !bit_flag)
        begin
          bit_cnt <= bit_cnt + 1;
        end
      else
        begin
          bit_cnt <= bit_cnt;
        end
    end

  // 数据移位寄存器
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        begin
          data_reg <= 8'd0;
        end
      else if (current_state == RECV && cyc_flag) // 计数完成一次收到一位数据
        begin
          data_reg[bit_cnt] <= din; // 接收数据
        end
    end

  // valid 输出寄存器
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        begin
          valid <= 1'b0;
        end
      else if (current_state == STOP && cyc_flag) // valid 升高，作为处理数据信号传送给 display_logic
        begin
          valid <= 1'b1;
        end
      else
        begin
          valid <= 1'b0;
        end
    end

  // data 输出寄存器
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        begin
          data <= 8'd0;
        end
      else if (current_state == STOP && cyc_flag)
        begin
          data <= data_reg; // 输出数据
        end
    end

endmodule
