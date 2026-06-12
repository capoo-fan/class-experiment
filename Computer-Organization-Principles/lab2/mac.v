`timescale 1ns / 1ps

module mac (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] x,
    input  wire [31:0] y,
    input  wire        start,
    output wire [31:0] z,
    output wire        busy
  );

  wire        busy0;
  wire        busy1;
  wire        busy2;
  wire        busy3;
  
  wire [31:0] x0 = {{24{x[ 7]}}, x[ 7: 0]};
  wire [31:0] x1 = {{24{x[15]}}, x[15: 8]};
  wire [31:0] x2 = {{24{x[23]}}, x[23:16]};
  wire [31:0] x3 = {{24{x[31]}}, x[31:24]};

  wire [31:0] y0 = {{24{y[ 7]}}, y[ 7: 0]};
  wire [31:0] y1 = {{24{y[15]}}, y[15: 8]};
  wire [31:0] y2 = {{24{y[23]}}, y[23:16]};
  wire [31:0] y3 = {{24{y[31]}}, y[31:24]};

  wire [63:0] result0;
  wire [63:0] result1;
  wire [63:0] result2;
  wire [63:0] result3;


  assign busy = busy0 | busy1 | busy2 | busy3;
  assign z    = result0[31:0] + result1[31:0] + result2[31:0] + result3[31:0];

  multiplier U_mul0 (
               .clk    (clk),
               .rst    (rst),
               .x      (x0),
               .y      (y0),
               .start  (start),
               .z      (result0),
               .busy   (busy0)
             );

  multiplier U_mul1 (
               .clk    (clk),
               .rst    (rst),
               .x      (x1),
               .y      (y1),
               .start  (start),
               .z      (result1),
               .busy   (busy1)
             );

  multiplier U_mul2 (
               .clk    (clk),
               .rst    (rst),
               .x      (x2),
               .y      (y2),
               .start  (start),
               .z      (result2),
               .busy   (busy2)
             );

  multiplier U_mul3 (
               .clk    (clk),
               .rst    (rst),
               .x      (x3),
               .y      (y3),
               .start  (start),
               .z      (result3),
               .busy   (busy3)
             );

endmodule
