module led_ctrl_unit #(
    parameter time_max = 100_000 - 1 // 1ms
  )(
    input wire rst,
    input wire clk,
    input wire [39:0] display,
    output reg [7:0] led_en,
    output reg [7:0] led_cx
  );
  localparam empty_char = 5'h1F; // 空字符显示为 '-'
  reg [16:0] refresh_cnt;
  reg [2:0] anode_select;
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        begin
          refresh_cnt <= 0;
          anode_select <= 3'd0;
        end
      else
        begin
          if (refresh_cnt == time_max)
            begin
              refresh_cnt <= 0;
              anode_select <= anode_select + 1; // 切换到下一个数码管
            end
          else
            begin
              refresh_cnt <= refresh_cnt + 1;
            end
        end
    end

  always @(*)
    begin
      case (anode_select)
        3'd0:
          led_en = 8'b11111110;
        3'd1:
          led_en = 8'b11111101;
        3'd2:
          led_en = 8'b11111011;
        3'd3:
          led_en = 8'b11110111;
        3'd4:
          led_en = 8'b11101111;
        3'd5:
          led_en = 8'b11011111;
        3'd6:
          led_en = 8'b10111111;
        3'd7:
          led_en = 8'b01111111;
        default:
          led_en = 8'b11111111; // 全灭
      endcase
    end

  reg [4:0] datadigit;
  always @(*)
    begin
      case (anode_select)
        3'd0:
          datadigit = display[ 4: 0];
        3'd1:
          datadigit = display[ 9: 5];
        3'd2:
          datadigit = display[14:10];
        3'd3:
          datadigit = display[19:15];
        3'd4:
          datadigit = display[24:20];
        3'd5:
          datadigit = display[29:25];
        3'd6:
          datadigit = display[34:30];
        3'd7:
          datadigit = display[39:35];
        default:
          datadigit = empty_char;
      endcase
    end
  always @(*)
    begin
      case (datadigit)
        5'h00:
          led_cx = 8'h03; //8'b1100_0011
        5'h01:
          led_cx = 8'h9F; //8'b1001_1111
        5'h02:
          led_cx = 8'h25; //8'b0010_0101
        5'h03:
          led_cx = 8'h0D; //8'b0000_1101
        5'h04:
          led_cx = 8'h99; //8'b1001_1001
        5'h05:
          led_cx = 8'h49; //8'b0100_1001
        5'h06:
          led_cx = 8'h41; //8'b0100_0001
        5'h07:
          led_cx = 8'h1F; //8'b0001_1111
        5'h08:
          led_cx = 8'h01; //8'b0000_0001
        5'h09:
          led_cx = 8'h09; //8'b0000_1001
        5'h0A:
          led_cx = 8'h11; // 8'b0001_0001; 
        5'h0B:
          led_cx = 8'hC1; // 8'b0100_0000;
        5'h0C:
          led_cx = 8'h63; // 8'b1100_0110;
        5'h0D:
          led_cx = 8'h85; // 8'b0010_0000;
        5'h0E:
          led_cx = 8'h61; //  8'b0110_0001;
        5'h0F:
          led_cx = 8'h71; // 8'b0111_0001;
        default:
          led_cx = 8'hFF; // 全灭
      endcase
    end
endmodule
