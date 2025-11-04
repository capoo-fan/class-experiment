// 延时法消抖
module debounce #(
    parameter cnt_max=2_000_000
  )(
    input wire clk,
    input wire rst,
    input wire button_in,
    output reg button_out
  );
  reg [23:0] count;
  reg state;
  always @(posedge clk or posedge rst)
    begin
      if (rst) // 复位
        begin
          state <= 0;
          button_out <= 0;
          count <= 0;
        end
      else
        begin
          if (button_in != state)
            begin
              state <= button_in;
              count <= 0;
            end
          else if (count < cnt_max)
            begin
              count <= count + 1;
            end
          else
            begin
              button_out <= state;
            end
        end
    end
endmodule
