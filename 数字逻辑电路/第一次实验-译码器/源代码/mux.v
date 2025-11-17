module mux(
    input wire        en,        
    input wire        mux_sel,    
    input wire [3:0]  input_a,   
    input wire [3:0]  input_b,   
    output reg [3:0]  output_c    
);
always @(*) 
begin
    if (en == 1'b0) 
    begin
        output_c = 4'b1111;
    end
    else 
    begin
        if (mux_sel == 1'b0) 
        begin
            output_c = input_a + input_b;
               end
        else 
        begin
            output_c = input_a - input_b;
        end
    end
end
endmodule
