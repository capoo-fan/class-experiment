`timescale 1ns / 1ps

`include "defines.vh"

// 主存地址位宽：32bit
// Cache容量：1KB
// Cache块大小：128bit / 4 * 32bit
// Cache块个数：64

module ICache(
    input  wire         cpu_clk,
    input  wire         cpu_rst,        // high active
    // Interface to CPU
    input  wire         inst_rreq,      // 来自CPU的取指请求
    input  wire [31:0]  inst_addr,      // 来自CPU的取指地址
    output reg          inst_valid,     // 输出给CPU的指令有效信号
    output reg  [31:0]  inst_out,       // 输出给CPU的指令
    // Interface to Read Bus
    input  wire         dev_rrdy,       // 主存就绪信号（高电平表示主存可接收ICache的读请求）
    output reg  [ 3:0]  cpu_ren,        // 输出给主存的读使能信号
    output reg  [31:0]  cpu_raddr,      // 输出给主存的读地址
    input  wire         dev_rvalid,     // 来自主存的数据有效信号
    input  wire [127:0] dev_rdata       // 来自主存的读数据
  );

`ifdef ENABLE_ICACHE    /******** 不要修改此行代码 ********/

  // 1KB / 16B = 64 lines
  // addr[31:10] : tag
  // addr[9:4]   : index
  // addr[3:2]   : word offset
  // addr[1:0]   : byte offset, ignored for 32-bit instruction fetch
  localparam TAG_WIDTH    = 22;
  localparam INDEX_WIDTH  = 6;
  localparam OFFSET_WIDTH = 2;
  localparam LINE_WIDTH   = 128;

  localparam IDLE        = 3'b000;
  localparam LOOKUP      = 3'b001;
  localparam MISS_REQ    = 3'b010;
  localparam MISS_WAIT   = 3'b011;
  localparam REFILL_DONE = 3'b100;

  reg [2:0] state, nstat;

  reg [31:0]  req_addr;
  reg [127:0] refill_data;

  // 注意：BRAM 只存 128-bit 指令块。
  // valid/tag 单独用寄存器数组保存，避免要求 blk_mem_gen_1 必须改成 151-bit。
  reg [63:0]              valid_table;
  reg [TAG_WIDTH-1:0]     tag_table [0:63];

  integer i;

  wire [TAG_WIDTH-1:0]    tag_from_cpu = req_addr[31:10];
  wire [OFFSET_WIDTH-1:0] offset       = req_addr[3:2];

  wire [INDEX_WIDTH-1:0]  req_index    = req_addr[9:4];
  wire [INDEX_WIDTH-1:0]  addr_index   = inst_addr[9:4];

  wire                    valid_bit    = valid_table[req_index];
  wire [TAG_WIDTH-1:0]    tag_from_cache = tag_table[req_index];

  wire                    hit = (state == LOOKUP) &&
                          valid_bit &&
                          (tag_from_cache == tag_from_cpu);

  wire                    cache_we = (state == MISS_WAIT) && dev_rvalid;

  // IDLE 阶段让 BRAM 提前读取 inst_addr 对应的 Cache line；
  // 进入 LOOKUP 后，douta 正好是该请求对应的 Cache line。
  wire [INDEX_WIDTH-1:0] cache_index =
       (state == IDLE) ? addr_index : req_index;

  wire [LINE_WIDTH-1:0] cache_line_w = dev_rdata;
  wire [LINE_WIDTH-1:0] cache_line_r;

  // ICache存储体：Block MEM IP核
  // 这里按 128-bit 数据块使用。如果你的 IP 曾被改成 151-bit，建议重新改回 128-bit。
  blk_mem_gen_1 U_isram (
                  .clka   (cpu_clk),
                  .wea    (cache_we),
                  .addra  (cache_index),
                  .dina   (cache_line_w),
                  .douta  (cache_line_r)
                );

  function [31:0] select_word;
    input [127:0] line;
    input [1:0]   word_offset;
    begin
      case (word_offset)
        2'b00:
          select_word = line[31:0];
        2'b01:
          select_word = line[63:32];
        2'b10:
          select_word = line[95:64];
        2'b11:
          select_word = line[127:96];
        default:
          select_word = 32'h0;
      endcase
    end
  endfunction

  // 状态寄存器、请求寄存器、输出寄存器
  always @(posedge cpu_clk or posedge cpu_rst)
    begin
      if (cpu_rst)
        begin
          state       <= IDLE;
          req_addr    <= 32'h0;
          refill_data <= 128'h0;
          valid_table <= 64'h0;

          for (i = 0; i < 64; i = i + 1)
            begin
              tag_table[i] <= {TAG_WIDTH{1'b0}};
            end

          inst_valid  <= 1'b0;
          inst_out    <= 32'h0;
          cpu_ren     <= 4'h0;
          cpu_raddr   <= 32'h0;
        end
      else
        begin
          state <= nstat;

          // 默认值：保证 inst_valid / cpu_ren 都只保持一个周期
          inst_valid <= 1'b0;
          inst_out   <= 32'h0;
          cpu_ren    <= 4'h0;

          case (state)
            IDLE:
              begin
                if (ins

            LOOKUP:
              begin
                if (hit)
                  begin
                    inst_valid <= 1'b1;
                    inst_out   <= select_word(cache_line_r, offset);
                  end
                else if (dev_rrdy)
                  begin
                    cpu_ren   <= 4'hF;
                    cpu_raddr <= {req_addr[31:4], 4'b0000};
                  end
              end

            MISS_REQ:
              begin
                if (dev_rrdy)
                  begin
                    cpu_ren   <= 4'hF;
                    cpu_raddr <= {req_addr[31:4], 4'b0000};
                  end
              end

            MISS_WAIT:
              begin
                if (dev_rvalid)
                  begin
                    refill_data            <= dev_rdata;
                    valid_table[req_index] <= 1'b1;
                    tag_table[req_index]   <= tag_from_cpu;
                  end
              end

            REFILL_DONE:
              begin
                inst_valid <= 1'b1;
                inst_out   <= select_word(refill_data, offset);
              end

            default:
              begin
                inst_valid <= 1'b0;
                inst_out   <= 32'h0;
                cpu_ren    <= 4'h0;
              end
          endcase
        end
    end

  // 状态转移逻辑
  always @(*)
    begin
      case (state)
        IDLE:
          begin
            nstat = inst_rreq ? LOOKUP : IDLE;
          end

        LOOKUP:
          begin
            if (hit)
              begin
                nstat = IDLE;
              end
            else
              begin
                nstat = dev_rrdy ? MISS_WAIT : MISS_REQ;
              end
          end

        MISS_REQ:
          begin
            nstat = dev_rrdy ? MISS_WAIT : MISS_REQ;
          end

        MISS_WAIT:
          begin
            nstat = dev_rvalid ? REFILL_DONE : MISS_WAIT;
          end

        REFILL_DONE:
          begin
            nstat = IDLE;
          end

        default:
          begin
            nstat = IDLE;
          end
      endcase
    end

  /******** 不要修改以下代码 ********/
`else

  localparam IDLE  = 2'b00;
  localparam STAT0 = 2'b01;
  localparam STAT1 = 2'b11;
  reg [1:0] state, nstat;

  always @(posedge cpu_clk or posedge cpu_rst)
    begin
      state <= cpu_rst ? IDLE : nstat;
    end

  always @(*)
    begin
      case (state)
        IDLE:
          nstat = inst_rreq ? (dev_rrdy ? STAT1 : STAT0) : IDLE;
        STAT0:
          nstat = dev_rrdy ? STAT1 : STAT0;
        STAT1:
          nstat = dev_rvalid ? IDLE : STAT1;
        default:
          nstat = IDLE;
      endcase
    end

  always @(posedge cpu_clk or posedge cpu_rst)
    begin
      if (cpu_rst)
        begin
          inst_valid <= 1'b0;
          cpu_ren    <= 4'h0;
        end
      else
        begin
          case (state)
            IDLE:
              begin
                inst_valid <= 1'b0;
                cpu_ren    <= (inst_rreq & dev_rrdy) ? 4'hF : 4'h0;
                cpu_raddr  <= inst_rreq ? inst_addr : 32'h0;
              end
            STAT0:
              begin
                cpu_ren    <= dev_rrdy ? 4'hF : 4'h0;
              end
            STAT1:
              begin
                cpu_ren    <= 4'h0;
                inst_valid <= dev_rvalid ? 1'b1 : 1'b0;
                inst_out   <= dev_rvalid ? dev_rdata[31:0] : 32'h0;
              end
            default:
              begin
                inst_valid <= 1'b0;
                cpu_ren    <= 4'h0;
              end
          endcase
        end
    end

`endif

endmodule
