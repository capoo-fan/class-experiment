module edge_detect (
    input wire clk,
    input wire rst,
    input wire signal,
    output wire pos_edge
  );
  reg sig_r0, sig_r1;
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        sig_r0 <= 1'b0;
      else
        sig_r0 <= signal;
    end
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        sig_r1 <= 1'b0;
      else
        sig_r1 <= sig_r0;
    end
  assign pos_edge = sig_r0 & !sig_r1;
endmodule
