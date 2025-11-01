// 延时法
module debounce (
    input wire clk,
    input wire rst,
    input wire button_in,
    output reg button_out
);
parameter freq = 100_000_000;
parameter stable = 20; //  20ms 稳定时间
localparam cnt_max = (freq / 1000) * stable; 
// localparam cnt_max = 2000;   // 仿真时长
reg [23:0] counter;
reg state;
always @(posedge clk or posedge rst) 
begin
    if (rst) 
    begin
        state <= 0;
        button_out <= 0;
        counter <= 0;
    end 
    else
    begin
        if (button_in != state) 
        begin
            state <= button_in; 
            counter <= 0;
        end 
        else if (counter < cnt_max) 
        begin
            counter <= counter + 1; 
        end 
        else 
        begin 
            button_out <= state; 
        end
    end
end
endmodule