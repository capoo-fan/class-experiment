`timescale 1ns / 1ps
module string_match_tb ();
  localparam CLK_FREQ = 100_000_000;          // clock frequency: 100 MHz
  localparam PERIOD   = 1e9/CLK_FREQ;         // clock cycle: 10ns
  localparam BAUD_RATE = 9600;
  localparam DIVIDER = CLK_FREQ / BAUD_RATE;  // clocks for one bit, should be 10416

  localparam CHAR_WAIT_TIME = (DIVIDER * 10 * PERIOD);
  localparam SEND_WAIT_TIME = (DIVIDER * 11 * PERIOD);

  reg clk;
  reg rst;
  reg valid;
  reg [7:0] recv_data;
  wire uart_tx;


  string_match u_string_match (
                 .clk        (clk),
                 .rst        (rst),
                 .valid      (valid),
                 .recv_data  (recv_data),
                 .uart_tx    (uart_tx)
               );

  always #(PERIOD/2) clk = ~clk;

  reg [7:0] test_data_start[0:5]; // start
  reg [7:0] test_data_stop[0:4];  // stop
  reg [7:0] test_data_hitsz[0:5]; // hitsz
  reg [7:0] test_data_xyz[0:3]; // xyzCR
  integer i;

  initial
    begin
      // start
      test_data_start[0] = 8'h73; // s
      test_data_start[1] = 8'h74; // t
      test_data_start[2] = 8'h61; // a
      test_data_start[3] = 8'h72; // r
      test_data_start[4] = 8'h74; // t
      test_data_start[5] = 8'h0D; // CR
      // stop
      test_data_stop[0] = 8'h73; // s
      test_data_stop[1] = 8'h74; // t
      test_data_stop[2] = 8'h6F; // o
      test_data_stop[3] = 8'h70; // p
      test_data_stop[4] = 8'h0D; // CR
      // hitsz
      test_data_hitsz[0] = 8'h68; // h
      test_data_hitsz[1] = 8'h69; // i
      test_data_hitsz[2] = 8'h74; // t
      test_data_hitsz[3] = 8'h73; // s
      test_data_hitsz[4] = 8'h7A; // z
      test_data_hitsz[5] = 8'h0D; // CR
      // xyz
      test_data_xyz[0] = 8'h78; // x
      test_data_xyz[1] = 8'h79; // y
      test_data_xyz[2] = 8'h7A; // z
      test_data_xyz[3] = 8'h0D; // CR
      #(200*DIVIDER*PERIOD)
       $finish;
    end

  initial
    begin
      clk = 0;
      rst = 1;
      valid = 0;
      recv_data = 8'h00;
      i=0;
      #(10*PERIOD) rst = 0;

      // start
      for (i = 0; i < 6; i = i + 1)
        send_byte(test_data_start[i]);

      #(SEND_WAIT_TIME * 2);
      for (i = 0; i < 5; i = i + 1)
        send_byte(test_data_stop[i]);

      #(SEND_WAIT_TIME * 2);

      // hitsz
      for (i = 0; i < 6; i = i + 1)
        send_byte(test_data_hitsz[i]);

      #(SEND_WAIT_TIME * 2);
      // xyz
      for (i = 0; i < 4; i = i + 1)
        send_byte(test_data_xyz[i]);

      #(SEND_WAIT_TIME * 2);
    end
  task send_byte(input [7:0] byte);
    integer j;
    begin
      #(CHAR_WAIT_TIME);
      recv_data = byte;
      valid = 1'b1;
      #(PERIOD);
      valid = 1'b0;
    end
  endtask
endmodule
