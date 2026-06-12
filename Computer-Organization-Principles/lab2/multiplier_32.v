`timescale 1ns / 1ps

module multiplier (
    input  wire        clk,
    input  wire        rst,     // high active
    input  wire [31:0] x,       // multiplicand
    input  wire [31:0] y,       // multiplier
    input  wire        start,   // 1 - multiplication should begin
    output reg  [63:0] z,       // product
    output wire        busy     // 1 - performing multiplication; 0 - multiplication ends
  );

  localparam IDLE = 1'b0;
  localparam CALC = 1'b1;

  reg        state;
  reg [5:0]  count;
  reg [31:0] M;
  reg [64:0] P;

  reg        busy_r;

  assign busy = busy_r;

  wire [31:0] A = P[64:33];
  wire [1:0]  booth_bits = P[1:0];

  wire [31:0] add_sub_val = (booth_bits == 2'b01) ? M :
       (booth_bits == 2'b10) ? (~M + 1'b1) : 32'd0;
  wire [31:0] next_A = A + add_sub_val;
  wire [64:0] next_P = {next_A[31], next_A, P[32:1]};

  always @(posedge clk or posedge rst)
  begin
    if (rst)
    begin
      state  <= IDLE;
      count  <= 6'd0;
      M      <= 32'd0;
      P      <= 65'd0;
      z      <= 64'd0;
      busy_r <= 1'b0;
    end
    else
    begin
      case (state)
        IDLE:
        begin
          if (start)
          begin
            M      <= x;
            P      <= {32'd0, y, 1'b0};
            count  <= 6'd0;
            busy_r <= 1'b1;
            state  <= CALC;
          end
        end

        CALC:
        begin
          P <= next_P;
          count <= count + 1'b1;
          if (count == 6'd31)
          begin
            state  <= IDLE;
            z      <= next_P[64:1];
            busy_r <= 1'b0;
          end
        end
      endcase
    end
  end
  // ****************************************************

endmodule
