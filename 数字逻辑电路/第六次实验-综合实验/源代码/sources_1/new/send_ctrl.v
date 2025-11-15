module send_ctrl (
    input wire clk,      
    input wire rst,  
    input wire s3,
    output wire uart_tx  
  );

  localparam cycles_per_bit = 10416; // 10417 一个比特的时间
  localparam char_wait_max = 10 * cycles_per_bit; //每个字符对应十个比特

  localparam [1:0] idle      = 2'b00;
  localparam [1:0] send_char = 2'b01;
  localparam [1:0] wait_char = 2'b10;

  reg [1:0]  current_state, next_state;
  reg [18:0] char_wait_cnt; //字符计数器
  reg [3:0]  pointer; // 指向当前发送字符
  reg        uart_valid;

  reg [7:0] string_rom ;
  always @(*)
    begin
      case (pointer)
        4'd0:
          string_rom = 8'h68;// 'h'
        4'd1:
          string_rom = 8'h69;// 'i'
        4'd2:
          string_rom = 8'h74;// 't'
        4'd3:
          string_rom = 8'h73;// 's'
        4'd4:
          string_rom = 8'h7A;// 'z'
        4'd5:
          string_rom = 8'h32;// '2'
        4'd6:
          string_rom = 8'h30;// '0'
        4'd7:
          string_rom = 8'h32;// '2'
        4'd8:
          string_rom = 8'h34;// '4'
        4'd9:
          string_rom = 8'h33;// '3'
        4'd10:
          string_rom = 8'h31;// '1'
        4'd11:
          string_rom = 8'h31;// '1'
        4'd12:
          string_rom = 8'h32;// '2'
        4'd13:
          string_rom = 8'h37;// '7'
        4'd14:
          string_rom = 8'h38;// '8'
        default:
          string_rom = 8'h00;
      endcase
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
                if (pointer == 4'd14)
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

  // 字符等待计数
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        char_wait_cnt <= 19'd0;
      else if (current_state == send_char)
        char_wait_cnt <= 19'd0;
      else if (current_state == wait_char)
        begin
          if (char_wait_cnt != char_wait_max - 1)
            char_wait_cnt <= char_wait_cnt + 1'b1;
        end
      else
        char_wait_cnt <= 19'd0;
    end

  // 发送字符计数
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        pointer <= 4'd0;
      else if (current_state == wait_char && char_wait_cnt == char_wait_max - 1)
        begin
          if (pointer == 4'd14)
            pointer <= 4'd0;
          else
            pointer <= pointer + 1'b1;
        end
    end


  // 实例uart_send 模块
  uart_send u_uart_send (
              .clk    (clk),
              .rst    (rst),
              .data   (string_rom),
              .valid  (uart_valid),
              .dout  (uart_tx)
            );
endmodule
