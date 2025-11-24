module mux (
    input wire SW0,
    input wire in0,
    input wire in1,
    output wire uart_tx
  );
  assign uart_tx = (SW0 == 1'b0) ? in0 : in1;
endmodule
