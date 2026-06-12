`timescale 1ns / 1ps
module testbench;
reg   clk;
reg   clr;
reg   en;
reg   [7:0] d;
reg   [2:0] wsel;
reg   [2:0] rsel;
wire  [7:0] q;

initial begin
    clr = 1'b1;
    clk = 1'b0;
    en = 1'b0;
    d = 8'b0;
    wsel = 3'b0;
    rsel = 3'b0;

    #10;
    clr = 1'b0;      
    en = 1'b1;     
    wsel = 3'b001;   
    d =8'b0001;        
        
    #10;            
    en = 1'b0;    //读取           
    rsel = 3'b001;

    #10 
    en = 1'b1;      
    wsel = 3'b0010;
    d = 8'b0010;
    #10;
    en = 1'b0;
    rsel = 3'b010; 

    #10 clr = 1'b1;
    #50 $finish;
end

always #5 clk = ~clk;
reg8file u_reg8file (
    .clk(clk),
    .clr(clr),
    .en(en),
    .d(d),
    .wsel(wsel),
    .rsel(rsel),
    .q(q)
);
endmodule