module send_ctrl (
    input wire clk,      // 100MHz 时钟
    input wire rst,    // 异步复位 (S1, 高电平有效)
    input wire s3,
    output wire uart_tx   // UART 发射引脚
  );

  localparam cycles_per_bit = 10416; // 10417 一个比特的时间
  localparam char_wait_max = 10 * cycles_per_bit; //每个字符对应十个比特

  localparam [1:0] idle      = 2'b00;
  localparam [1:0] send_char = 2'b01;
  localparam [1:0] wait_char = 2'b10;


  reg [1:0]  current_state;
  reg [1:0]  next_state;
  reg [18:0] char_wait_cnt; //字符计数器
  reg [3:0]  pointer; // 指向当前发送字符
  reg        uart_valid;

  reg [7:0] string_rom [0:14];
  always @(*)
    begin
      string_rom[0]  = 8'h68;// 'h'
      string_rom[1]  = 8'h69;// 'i'
      string_rom[2]  = 8'h74;// 't'
      string_rom[3]  = 8'h73;// 's'
      string_rom[4]  = 8'h7A;// 'z'
      string_rom[5]  = 8'h32;// '2'
      string_rom[6]  = 8'h30;// '0'
      string_rom[7]  = 8'h32;// '2'
      string_rom[8]  = 8'h34;// '4'
      string_rom[9]  = 8'h33;// '3'
      string_rom[10] = 8'h31;// '1'
      string_rom[11] = 8'h31;// '1'
      string_rom[12] = 8'h32;// '2'
      string_rom[13] = 8'h37;// '7'
      string_rom[14] = 8'h38;// '8'
    end

  // 状态转移
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        current_state <= idle;
      else
        current_state <= next_state;
    end
  always @(*)
    begin
      case (current_state)
        idle:
          begin
            if (s3)
              next_state = send_char;
            else
              next_state = idle;
          end
        send_char:
          next_state = wait_char;
        wait_char:
          begin
            if (char_wait_cnt == char_wait_max - 1)
              begin
                if (pointer == 14)
                  next_state = idle;
                else
                  next_state = send_char;
              end
            else
              next_state = wait_char; // 保持在等待状态
          end
        default:
          next_state = idle;
      endcase
    end

  // uart_valid 
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        uart_valid <= 1'b0;
      else
        uart_valid <= (current_state == send_char); 
    end

  // 字符发送等待计数
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        char_wait_cnt <= 19'd0;
      else if (current_state == send_char)
        char_wait_cnt <= 19'd0;
      else if (current_state == wait_char)
        begin
          if (char_wait_cnt == char_wait_max - 1)
            char_wait_cnt <= 19'd0; 
          else
            char_wait_cnt <= char_wait_cnt + 1'b1;
        end
    end

  // 发送字符计数
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        pointer <= 4'd0;
      else if (current_state == wait_char && char_wait_cnt == char_wait_max - 1)
        begin
          if (pointer == 14)
            pointer <= 4'd0;
          else
            pointer <= pointer + 1'b1;
        end
    end


  // 实例uart_send 模块
  uart_send u_uart_send (
              .clk    (clk),
              .rst    (rst),
              .data   (string_rom[pointer]),
              .valid  (uart_valid),
              .dout  (uart_tx)
            );
endmodule
