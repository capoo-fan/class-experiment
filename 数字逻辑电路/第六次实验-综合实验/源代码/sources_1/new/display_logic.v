module display_logic (
    input wire clk,
    input wire rst,
    input wire valid,
    input wire [7:0] recv_data,
    output wire [39:0] display_data // 传输给led_ctrl_unit
  );
  localparam empty_char = 5'h1F; // 全灭
 
  reg  [3:0] hex_out;      // 解码后的 hex 值
  reg        valid_char;   // 判断字符是否有效

  // 存储6个接收到的字符 (对应数码管 [7:2])
  reg [4:0] display_slots_chars [5:0];
  // 存储接收计数
  reg [7:0] recv_count;

  // 存储计数器的十位和个位
  wire [3:0] count_tens;
  wire [3:0] count_ones;

  // ascii 转换为 hex ，同时判断是否有效
  always @(*)
    begin
      case (recv_data)
        8'h30:
          {hex_out, valid_char} = {4'h0, 1'b1};
        8'h31:
          {hex_out, valid_char} = {4'h1, 1'b1};
        8'h32:
          {hex_out, valid_char} = {4'h2, 1'b1};
        8'h33:
          {hex_out, valid_char} = {4'h3, 1'b1};
        8'h34:
          {hex_out, valid_char} = {4'h4, 1'b1};
        8'h35:
          {hex_out, valid_char} = {4'h5, 1'b1};
        8'h36:
          {hex_out, valid_char} = {4'h6, 1'b1};
        8'h37:
          {hex_out, valid_char} = {4'h7, 1'b1};
        8'h38:
          {hex_out, valid_char} = {4'h8, 1'b1};
        8'h39:
          {hex_out, valid_char} = {4'h9, 1'b1};
        8'h41, 8'h61: //统一显示大写
          {hex_out, valid_char} = {4'hA, 1'b1}; 
        8'h42, 8'h62:
          {hex_out, valid_char} = {4'hB, 1'b1}; 
        8'h43, 8'h63:
          {hex_out, valid_char} = {4'hC, 1'b1}; 
        8'h44, 8'h64:
          {hex_out, valid_char} = {4'hD, 1'b1}; 
        8'h45, 8'h65:
          {hex_out, valid_char} = {4'hE, 1'b1}; 
        8'h46, 8'h66:
          {hex_out, valid_char} = {4'hF, 1'b1}; 
        default:
          {hex_out, valid_char} = {4'hF, 1'b0};
      endcase
    end

  // 接受的计数器
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        begin
          recv_count <= 8'h00;
        end
      else if (valid && valid_char) // 有效字符计数加1
        begin
          recv_count <= recv_count + 1;
        end
    end

  // 移位寄存器
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        begin
          display_slots_chars[0] <= empty_char; 
          display_slots_chars[1] <= empty_char;
          display_slots_chars[2] <= empty_char;
          display_slots_chars[3] <= empty_char;
          display_slots_chars[4] <= empty_char;
          display_slots_chars[5] <= empty_char;
        end
      else if (valid && valid_char)
        begin
          display_slots_chars[5] <= display_slots_chars[4]; 
          display_slots_chars[4] <= display_slots_chars[3]; 
          display_slots_chars[3] <= display_slots_chars[2]; 
          display_slots_chars[2] <= display_slots_chars[1]; 
          display_slots_chars[1] <= display_slots_chars[0]; 
          display_slots_chars[0] <= {1'b0, hex_out};              
        end
    end

  // 计数器
  assign count_tens = (recv_count / 10) % 10; // 十位
  assign count_ones = recv_count % 10;       // 个位

  // display_data 拼接，然后送给 led_ctrl_unit处理
  assign display_data = {
           display_slots_chars[5], 
           display_slots_chars[4], 
           display_slots_chars[3], 
           display_slots_chars[2], 
           display_slots_chars[1], 
           display_slots_chars[0], 
           {1'b0, count_tens},             
           {1'b0, count_ones}              
         };
endmodule
