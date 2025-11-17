module reg8file (
    input  wire clk,  
    input  wire clr,  //S1  
    input  wire en, //SW23
    input  wire [7:0] d,  //SW7-0
    input  wire [2:0] wsel, //Sw22-20
    input  wire [2:0] rsel, //Sw10-8
    output reg  [7:0] q    //GLD7-0
);
reg [7:0] regfile [7:0];
integer i;
always @(posedge clk or posedge clr) 
begin
    if (clr) 
    begin
        for (i = 0; i < 8; i = i + 1) 
        begin
            regfile[i] <= 8'b0; 
        end 
    end 
    else if (en) 
    begin
        regfile[wsel] <= d;
    end 
end
always @(*) 
begin
    q <= regfile[rsel];
end
endmodule