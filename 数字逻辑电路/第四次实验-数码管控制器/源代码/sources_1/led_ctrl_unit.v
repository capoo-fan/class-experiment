module led_ctrl_unit #(
    parameter time_max = 100_000 - 1 // 1ms
  )(
    input wire rst,
    input wire clk,
    input wire [31:0] display,
    output reg [7:0] led_en,
    output reg [7:0] led_cx
  );
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

  reg [3:0] datadigit;

  always @(*)
    begin
      case (anode_select)
        3'd0:
          datadigit = display[ 3: 0];
        3'd1:
          datadigit = display[ 7: 4];
        3'd2:
          datadigit = display[11: 8];
        3'd3:
          datadigit = display[15:12];
        3'd4:
          datadigit = display[19:16];
        3'd5:
          datadigit = display[23:20];
        3'd6:
          datadigit = display[27:24];
        3'd7:
          datadigit = display[31:28];
        default:
          datadigit = 4'hF;
      endcase
    end
  always @(*)
    begin
      case (datadigit)
        4'h0:
          led_cx = 8'h03; //8'b1100_0011
        4'h1:
          led_cx = 8'h9F; //8'b1001_1111
        4'h2:
          led_cx = 8'h25; //8'b0010_0101
        4'h3:
          led_cx = 8'h0D; //8'b0000_1101
        4'h4:
          led_cx = 8'h99; //8'b1001_1001
        4'h5:
          led_cx = 8'h49; //8'b0100_1001
        4'h6:
          led_cx = 8'h41; //8'b0100_0001
        4'h7:
          led_cx = 8'h1F; //8'b0001_1111
        4'h8:
          led_cx = 8'h01; //8'b0000_0001
        4'h9:
          led_cx = 8'h09; //8'b0000_1001
        default:
          led_cx = 8'hFF; // 全灭
      endcase
    end
endmodule
