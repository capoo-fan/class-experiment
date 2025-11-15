// 状态转移实现
module string_match(
    input  wire        clk,
    input  wire        rst,
    input  wire        valid,
    input  wire [7:0]  recv_data,
    output wire        uart_tx
  );

  // 状态枚举
  localparam [3:0] IDLE        = 4'b0000;
  localparam [3:0] s_state     = 4'b0001;
  localparam [3:0] st_state    = 4'b0010;
  localparam [3:0] sta_state   = 4'b0011;
  localparam [3:0] star_state  = 4'b0100;
  localparam [3:0] start_state = 4'b0101;
  localparam [3:0] sto_state   = 4'b0110;
  localparam [3:0] stop_state  = 4'b0111;
  localparam [3:0] h_state     = 4'b1000;
  localparam [3:0] hi_state    = 4'b1001;
  localparam [3:0] hit_state   = 4'b1010;
  localparam [3:0] hits_state  = 4'b1011;
  localparam [3:0] hitsz_state = 4'b1100;
  localparam [3:0] end_state   = 4'b1101;

  // 字符常量
  localparam [7:0] s   = 8'h73;
  localparam [7:0] t   = 8'h74;
  localparam [7:0] a   = 8'h61;
  localparam [7:0] r   = 8'h72;
  localparam [7:0] o   = 8'h6F;
  localparam [7:0] p   = 8'h70;
  localparam [7:0] h   = 8'h68;
  localparam [7:0] i   = 8'h69;
  localparam [7:0] z   = 8'h7A;

  // 大写字符常量
  localparam [7:0] S = 8'h53;
  localparam [7:0] T = 8'h54;
  localparam [7:0] A = 8'h41;
  localparam [7:0] R = 8'h52;
  localparam [7:0] O = 8'h4F;
  localparam [7:0] P = 8'h50;
  localparam [7:0] H = 8'h48;
  localparam [7:0] I = 8'h49;
  localparam [7:0] Z = 8'h5A;

  // 结束符支持：CR / LF
  localparam [7:0] CR  = 8'h0D;
  localparam [7:0] LF  = 8'h0A;

  reg [3:0] current_state, next_state;
  reg       uart_valid;
  reg       flag;



  // 状态寄存器
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        current_state <= IDLE;
      else
        current_state <= next_state;
    end

  // 仅在检测到新字节时才计算 next_state，其余时间保持
  always @(*)
    begin
      if (valid)
        begin
          case (current_state)
            IDLE:
              case (recv_data)
                s,S:
                  next_state = s_state;
                h,H:
                  next_state = h_state;
                CR,LF:
                  next_state = end_state;
                default:
                  next_state = IDLE;
              endcase
            s_state:
              case (recv_data)
                t,T:
                  next_state = st_state;
                s,S:
                  next_state = s_state;
                h,H:
                  next_state = h_state;
                CR,LF:
                  next_state = end_state;
                default:
                  next_state = IDLE;
              endcase
            st_state:
              case (recv_data)
                a,A:
                  next_state = sta_state;
                o,O:
                  next_state = sto_state;
                s,S:
                  next_state = s_state;
                h,H:
                  next_state = h_state;
                CR,LF:
                  next_state = end_state;
                default:
                  next_state = IDLE;
              endcase
            sta_state:
              case (recv_data)
                r,R:
                  next_state = star_state;
                s,S:
                  next_state = s_state;
                h,H:
                  next_state = h_state;
                CR,LF:
                  next_state = end_state;
                default:
                  next_state = IDLE;
              endcase
            star_state:
              case (recv_data)
                t,T:
                  next_state = start_state;
                s,S:
                  next_state = s_state;
                h,H:
                  next_state = h_state;
                CR,LF:
                  next_state = end_state;
                default:
                  next_state = IDLE;
              endcase
            start_state:
              case (recv_data)
                CR,LF:
                  next_state = end_state;
                s,S:
                  next_state = s_state;
                h,H:
                  next_state = h_state;
                default:
                  next_state = IDLE;
              endcase
            sto_state:
              case (recv_data)
                p,P:
                  next_state = stop_state;
                s,S:
                  next_state = s_state;
                h,H:
                  next_state = h_state;
                CR,LF:
                  next_state = end_state;
                default:
                  next_state = IDLE;
              endcase
            stop_state:
              case (recv_data)
                CR,LF:
                  next_state = end_state;
                s,S:
                  next_state = s_state;
                h,H:
                  next_state = h_state;
                default:
                  next_state = IDLE;
              endcase
            h_state:
              case (recv_data)
                i,I:
                  next_state = hi_state;
                s,S:
                  next_state = s_state;
                h,H:
                  next_state = h_state;
                CR,LF:
                  next_state = end_state;
                default:
                  next_state = IDLE;
              endcase
            hi_state:
              case (recv_data)
                t,T:
                  next_state = hit_state;
                s,S:
                  next_state = s_state;
                h,H:
                  next_state = h_state;
                CR,LF:
                  next_state = end_state;
                default:
                  next_state = IDLE;
              endcase
            hit_state:
              case (recv_data)
                s,S:
                  next_state = hits_state;
                h,H:
                  next_state = h_state;
                CR,LF:
                  next_state = end_state;
                default:
                  next_state = IDLE;
              endcase
            hits_state:
              case (recv_data)
                z,Z:
                  next_state = hitsz_state;
                s,S:
                  next_state = s_state;
                h,H:
                  next_state = h_state;
                CR,LF:
                  next_state = end_state;
                default:
                  next_state = IDLE;
              endcase
            hitsz_state:
              case (recv_data)
                CR,LF:
                  next_state = end_state;
                s,S:
                  next_state = s_state;
                h,H:
                  next_state = h_state;
                default:
                  next_state = IDLE;
              endcase
            end_state:
              next_state = IDLE;
            default:
              next_state = IDLE;
          endcase
        end
      else
        next_state = current_state; // 保持当前状态
    end


  // flag：仅在新字节到达时更新
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        flag <= 1'b0;
      else if (valid)
        begin
          case (next_state)
            start_state, stop_state, hitsz_state:
              flag <= 1'b1;
            end_state:
              flag <= 1'b0;
            default:
              flag <= flag;
          endcase
        end
    end

  reg [1:0] pointer;
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        pointer <= 2'd0;
      else if (valid)
        begin
          case (next_state)
            end_state:
              if (!flag)
                pointer <= 2'd0;
            start_state:
              pointer <= 2'd1;
            stop_state:
              pointer <= 2'd2;
            hitsz_state:
              pointer <= 2'd3;
            default:
              pointer <= pointer;
          endcase
        end
    end
  // 将要发送的数据
  reg [7:0] string_rom;
  always @(*)
    begin
      case (pointer)
        2'd0:
          string_rom = 8'h30; // '0'
        2'd1:
          string_rom = 8'h31; // '1'
        2'd2:
          string_rom = 8'h32; // '2'
        2'd3:
          string_rom = 8'h33; // '3'
        default:
          string_rom = 8'h00;
      endcase
    end

  // 只在新字节时给出单拍 valid
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        uart_valid <= 1'b0;
      else
        uart_valid <= valid &&
                   (next_state==start_state ||
                    next_state==stop_state  ||
                    next_state==hitsz_state ||
                    (next_state==end_state && !flag));
    end

  uart_send u_uart_send (
              .clk   (clk),
              .rst   (rst),
              .data  (string_rom),
              .valid (uart_valid),
              .dout  (uart_tx)
            );

endmodule
