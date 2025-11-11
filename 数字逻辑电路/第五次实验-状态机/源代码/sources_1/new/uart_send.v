module uart_send(
    input         clk,
    input         rst,      // 高电平有效, 异步复位
    input         valid,    // 1个时钟周期的高电平脉冲
    input [7:0]   data,     // 待发送的8位数据
    output reg    dout      // 发送信号
  );
  localparam IDLE = 2'b00;  // 空闲状态, 发送高电平
  localparam START = 2'b01;// 起始状态, 发送起始位
  localparam DATA = 2'b10;  // 数据状态, 将8位数据发送出去
  localparam STOP = 2'b11;// 停止状态, 发送停止位

  localparam cnt_max = 10415; // 波特率计数最大值

  reg [1:0] current_state; //存储四种状态
  reg [1:0] next_state;
  
  reg [2:0]  bit_cnt;  // 看发送到了第几位数据

  // 波特率时间计数器
  reg [15:0] baud_cnt; // 记录波特率周期计数
  wire baud_tick;
  assign baud_tick = (baud_cnt == cnt_max); // 计数到10416
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        begin
          baud_cnt <= 16'd0;
        end
      else if (current_state == IDLE)
        begin
          baud_cnt <= 16'd0; // 空闲时清零
        end
      else if (baud_tick)
        begin
          baud_cnt <= 16'd0;
        end
      else
        begin
          baud_cnt <= baud_cnt + 1'b1;
        end
    end

  // 状态转换
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
            if (valid)  //准备发送数据
              begin
                next_state = START;
              end
          end
        START:
          begin
            if (baud_tick) // 开始发送
              begin
                next_state = DATA;
              end
          end
        DATA:
          begin
            if (baud_tick)
              begin
                if (bit_cnt == 3'd7)
                  begin
                    next_state = STOP;
                  end
                else
                  begin
                    next_state = DATA;
                  end
              end
          end
        STOP:
          begin
            if (baud_tick)
              begin
                next_state = IDLE;
              end
          end
        default:
          begin
            next_state = IDLE;
          end
      endcase
    end

  // data_buf 保存数据
  reg [7:0] data_buf;  // 存储待发送的数据
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        begin
          data_buf <= 8'd0;
        end
      else if (current_state == IDLE && next_state == START)
        begin
          data_buf <= data;
        end
    end

  // bit_cnt 计算发送多少个数据
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        begin
          bit_cnt <= 3'd0;
        end
      else if (current_state == START && next_state == DATA)
        begin
          bit_cnt <= 3'd0;
        end
      else if (current_state == DATA && baud_tick)
        begin
          bit_cnt <= bit_cnt + 1'b1;
        end
    end

  // dout 输出
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        begin
          dout <= 1'b1; // 复位时，总线空闲
        end
      else
        begin
          case (current_state)
            IDLE:
              begin
                dout <= 1'b1;
              end
            START:
              begin
                dout <= 1'b0;
              end
            DATA:
              begin
                dout <= data_buf[bit_cnt];
              end
            STOP:
              begin
                dout <= 1'b1;
              end
            default:
              begin
                dout <= 1'b1;
              end
          endcase
        end
    end

endmodule
