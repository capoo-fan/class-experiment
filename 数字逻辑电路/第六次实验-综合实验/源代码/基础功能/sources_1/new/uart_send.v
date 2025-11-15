module uart_send (
    input         clk,
    input         rst,
    input         valid,
    input [7:0]   data,
    output reg    dout
  );
  localparam IDLE = 2'b00;  // 空闲态, 发送高电平
  localparam START = 2'b01;// 起始态, 发送起始位
  localparam DATA = 2'b10;  // 数据态, 将8位数据发送出去
  localparam STOP = 2'b11;// 停止态, 发送停止位

  localparam cnt_max = 10415; // 0-10415 共 10416 个周期

  reg [1:0] current_state; //存储状态极的四种状态
  reg [1:0] next_state;
  reg [7:0] data_buf;  // 存储待发送的数据
  reg [15:0] baud_cnt; // 波特率计数器
  reg [2:0]  bit_cnt;  // 数据位计数器 ，发送七个数据

  wire baud_tick;
  assign baud_tick = (baud_cnt == cnt_max); // 计数到10416 , 脉冲为高

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
      next_state = current_state;
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
                if (bit_cnt == 3'd7) //发送完成，停止
                  begin
                    next_state = STOP;
                  end
                else
                  begin
                    next_state = DATA; //继续发送数据
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

  //波特率计数器
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

  // dout
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        begin
          dout <= 1'b1;
        end
      else
        begin
          case (current_state)
            IDLE:
              dout <= 1'b1;
            START:
              dout <= 1'b0;
            DATA:
              dout <= data_buf[bit_cnt];
            STOP:
              dout <= 1'b1;
            default:
              dout <= 1'b1;
          endcase
        end
    end

  // data_buf计数器
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

  // bit_cnt 计数器
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
endmodule
