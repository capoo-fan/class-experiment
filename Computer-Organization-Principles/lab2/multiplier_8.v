module multiplier(
    input wire clk,
    input wire rst,
    input wire [7:0] x,
    input wire [7:0] y,
    input wire start,
    output reg [15:0] z,
    output reg busy
  );
  localparam IDLE = 2'b00;
  localparam CALC = 2'b01;
  localparam DONE = 2'b10;

  reg [1:0]  state;
  reg [3:0]  count;
  reg [7:0]  M;
  reg [16:0] P;


  wire [7:0] A = P[16:9];
  wire [1:0] booth_bits = P[1:0];

  wire [7:0] add_sub_val = (booth_bits == 2'b01) ? M :
       (booth_bits == 2'b10) ? (~M + 1'b1) : 8'd0;

  wire [7:0] next_A = A + add_sub_val;

  wire [16:0] next_P = {next_A[7], next_A, P[8:1]};

  always @(posedge clk or posedge rst)
  begin
    if (rst)
    begin
      state <= IDLE;
      busy <= 1'b0;
      z <= 16'd0;
      count <= 4'd0;
      M <= 8'd0;
      P <= 17'd0;
    end
    else
    begin
      case (state)
        IDLE:
        begin
          if (start)
          begin
            M <= x;
            P <= {8'd0, y, 1'b0};
            busy <= 1'b1;
            count <= 4'd0;
            state <= CALC;
          end
          else
          begin
            busy <= 1'b0;
          end
        end

        CALC:
        begin
          P <= next_P;
          count <= count + 1'b1;
          if (count == 4'd7)
          begin
            state <= DONE;
          end
        end

        DONE:
        begin
          busy <= 1'b0;
          z <= P[16:1];
          state <= IDLE;
        end

        default:
          state <= IDLE;
      endcase
    end
  end

endmodule
