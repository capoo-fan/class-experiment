`timescale 1ns / 1ps
module dff (
    input      clk, //Y18
    input      clr,  // S1
    input      en , //SW23
    input      d  ,  //SW0
    output reg q    //GLD0
);
always @(posedge clk or posedge clr) 
begin
    if (clr) 
    begin
        q<= 1'b0;
    end 
    else if (en) 
    begin
        q <= d;
    end
    else 
    begin
        q <= q;
    end
end
endmodule


