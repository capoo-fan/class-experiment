`timescale 1ns / 1ps

`include "defines.vh"

// 主存地址位宽：32bit
// Cache容量：1KB
// Cache块大小：128bit (4*32bit)
// Cache块个数：?

module DCache(
    input  wire         cpu_clk,
    input  wire         cpu_rst,        // high active
    // Interface to CPU
    input  wire [ 3:0]  data_ren,       // 来自CPU的读使能信号
    input  wire [31:0]  data_addr,      // 来自CPU的地址（读、写共用）
    output reg          data_valid,     // 输出给CPU的数据有效信号
    output reg  [31:0]  data_rdata,     // 输出给CPU的读数据
    input  wire [ 3:0]  data_wen,       // 来自CPU的写使能信号
    input  wire [31:0]  data_wdata,     // 来自CPU的写数据
    output reg          data_wresp,     // 输出给CPU的写响应（高电平表示DCache已完成写操作）
    // Interface to Write Bus
    input  wire         dev_wrdy,       // 主存/外设的写就绪信号（高电平表示主存/外设可接收DCache的写请求）
    output reg  [ 3:0]  cpu_wen,        // 输出给主存/外设的写使能信号
    output reg  [31:0]  cpu_waddr,      // 输出给主存/外设的写地址
    output reg  [31:0]  cpu_wdata,      // 输出给主存/外设的写数据
    // Interface to Read Bus
    input  wire         dev_rrdy,       // 主存/外设的读就绪信号（高电平表示主存/外设可接收DCache的读请求）
    output reg  [ 3:0]  cpu_ren,        // 输出给主存/外设的读使能信号
    output reg  [31:0]  cpu_raddr,      // 输出给主存/外设的读地址
    input  wire         dev_rvalid,     // 来自主存/外设的数据有效信号
    input  wire [127:0] dev_rdata       // 来自主存/外设的读数据
  );

  // Peripherals access should be uncached.
  wire uncached = (data_addr[31:16] == 16'hFFFF) & (data_ren != 4'h0 | data_wen != 4'h0) ? 1'b1 : 1'b0;

`ifdef ENABLE_DCACHE    /******** 不要修改此行代码 ********/

  // ============================================================
  // Direct-mapped DCache
  // Cache size : 1KB
  // Block size : 128bit = 16B = 4 words
  // Line count : 64
  //
  // Address format:
  //   tag    = addr[31:10]  22 bits
  //   index  = addr[9:4]     6 bits
  //   offset = addr[3:2]     2 bits
  //
  // Write policy:
  //   write-through
  //   no-write-allocate
  //
  // Important:
  //   U_dsram only stores the 128-bit data block.
  //   valid/tag are stored in registers, so blk_mem_gen_1 should
  //   be configured as 128-bit wide and depth >= 64.
  // ============================================================

  localparam TAG_WIDTH    = 22;
  localparam INDEX_WIDTH  = 6;
  localparam OFFSET_WIDTH = 2;
  localparam LINE_WIDTH   = 128;

  localparam S_IDLE         = 4'd0;
  localparam S_RD_LOOKUP    = 4'd1;
  localparam S_RD_MISS_REQ  = 4'd2;
  localparam S_RD_MISS_WAIT = 4'd3;
  localparam S_RD_UC_REQ    = 4'd4;
  localparam S_RD_UC_WAIT   = 4'd5;
  localparam S_RD_RESP      = 4'd6;
  localparam S_WR_LOOKUP    = 4'd7;
  localparam S_WR_BUS_REQ   = 4'd8;
  localparam S_WR_BUS_WAIT  = 4'd9;
  localparam S_WR_RESP      = 4'd10;

  reg [3:0] state, nstat;

  // Latched CPU request.
  reg [31:0] op_addr;
  reg [ 3:0] op_ren;
  reg [ 3:0] op_wen;
  reg [31:0] op_wdata;

  // Registered read response.
  reg [31:0] resp_rdata;

  // Valid/tag arrays. Data block is stored in BRAM.
  reg [63:0]          valid_table;
  reg [TAG_WIDTH-1:0] tag_table [0:63];

  wire [TAG_WIDTH-1:0]    op_tag    = op_addr[31:10];
  wire [INDEX_WIDTH-1:0]  op_index  = op_addr[9:4];
  wire [OFFSET_WIDTH-1:0] op_offset = op_addr[3:2];

  wire [INDEX_WIDTH-1:0]  cpu_index = data_addr[9:4];
  wire                    req_uncached = (data_addr[31:16] == 16'hFFFF);

  wire read_fire  = (state == S_IDLE) && (|data_ren);
  wire write_fire = (state == S_IDLE) && !(|data_ren) && (|data_wen);

  wire valid_bit = valid_table[op_index];
  wire [TAG_WIDTH-1:0] tag_from_cache = tag_table[op_index];

  wire hit_r = (state == S_RD_LOOKUP) &&
       valid_bit &&
       (tag_from_cache == op_tag);

  wire hit_w = (state == S_WR_LOOKUP) &&
       valid_bit &&
       (tag_from_cache == op_tag);

  wire [LINE_WIDTH-1:0] cache_line_r;
  wire [LINE_WIDTH-1:0] cache_line_w;

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

  function [31:0] merge_word;
    input [31:0] old_word;
    input [31:0] new_word;
    input [3:0]  byte_wen;
    begin
      merge_word[ 7: 0] = byte_wen[0] ? new_word[ 7: 0] : old_word[ 7: 0];
      merge_word[15: 8] = byte_wen[1] ? new_word[15: 8] : old_word[15: 8];
      merge_word[23:16] = byte_wen[2] ? new_word[23:16] : old_word[23:16];
      merge_word[31:24] = byte_wen[3] ? new_word[31:24] : old_word[31:24];
    end
  endfunction

  reg [127:0] wr_cache_data;

  always @(*)
    begin
      wr_cache_data = cache_line_r;

      case (op_offset)
        2'b00:
          wr_cache_data[31:0]    = merge_word(cache_line_r[31:0],    op_wdata, op_wen);
        2'b01:
          wr_cache_data[63:32]   = merge_word(cache_line_r[63:32],   op_wdata, op_wen);
        2'b10:
          wr_cache_data[95:64]   = merge_word(cache_line_r[95:64],   op_wdata, op_wen);
        2'b11:
          wr_cache_data[127:96]  = merge_word(cache_line_r[127:96],  op_wdata, op_wen);
        default:
          wr_cache_data = cache_line_r;
      endcase
    end

  wire read_refill_we = (state == S_RD_MISS_WAIT) && dev_rvalid;
  wire write_hit_we   = (state == S_WR_LOOKUP) && hit_w;

  wire cache_we = read_refill_we || write_hit_we;

  wire [INDEX_WIDTH-1:0] cache_index =
       (state == S_IDLE && ((|data_ren) || (|data_wen))) ? cpu_index :
       op_index;

  assign cache_line_w = read_refill_we ? dev_rdata : wr_cache_data;

  // DCache data array: 64 lines x 128 bits.
  blk_mem_gen_1 U_dsram (
                  .clka   (cpu_clk),
                  .wea    (cache_we),
                  .addra  (cache_index),
                  .dina   (cache_line_w),
                  .douta  (cache_line_r)
                );

  // State register and request/response registers.
  integer i;
  always @(posedge cpu_clk or posedge cpu_rst)
    begin
      if (cpu_rst)
        begin
          state       <= S_IDLE;
          op_addr     <= 32'h0;
          op_ren      <= 4'h0;
          op_wen      <= 4'h0;
          op_wdata    <= 32'h0;
          resp_rdata  <= 32'h0;
          valid_table <= 64'h0;

          for (i = 0; i < 64; i = i + 1)
            begin
              tag_table[i] <= {TAG_WIDTH{1'b0}};
            end
        end
      else
        begin
          state <= nstat;

          if (read_fire)
            begin
              op_addr  <= data_addr;
              op_ren   <= data_ren;
              op_wen   <= 4'h0;
              op_wdata <= 32'h0;
            end
          else if (write_fire)
            begin
              op_addr  <= data_addr;
              op_ren   <= 4'h0;
              op_wen   <= data_wen;
              op_wdata <= data_wdata;
            end

          if ((state == S_RD_LOOKUP) && hit_r)
            begin
              resp_rdata <= select_word(cache_line_r, op_offset);
            end

          if ((state == S_RD_MISS_WAIT) && dev_rvalid)
            begin
              resp_rdata            <= select_word(dev_rdata, op_offset);
              valid_table[op_index] <= 1'b1;
              tag_table[op_index]   <= op_tag;
            end

          if ((state == S_RD_UC_WAIT) && dev_rvalid)
            begin
              resp_rdata <= dev_rdata[31:0];
            end
        end
    end

  // Next-state logic.
  always @(*)
    begin
      case (state)
        S_IDLE:
          begin
            if (|data_ren)
              begin
                nstat = req_uncached ? S_RD_UC_REQ : S_RD_LOOKUP;
              end
            else if (|data_wen)
              begin
                nstat = req_uncached ? S_WR_BUS_REQ : S_WR_LOOKUP;
              end
            else
              begin
                nstat = S_IDLE;
              end
          end

        S_RD_LOOKUP:
          begin
            if (hit_r)
              nstat = S_RD_RESP;
            else
              nstat = dev_rrdy ? S_RD_MISS_WAIT : S_RD_MISS_REQ;
          end

        S_RD_MISS_REQ:
          begin
            nstat = dev_rrdy ? S_RD_MISS_WAIT : S_RD_MISS_REQ;
          end

        S_RD_MISS_WAIT:
          begin
            nstat = dev_rvalid ? S_RD_RESP : S_RD_MISS_WAIT;
          end

        S_RD_UC_REQ:
          begin
            nstat = dev_rrdy ? S_RD_UC_WAIT : S_RD_UC_REQ;
          end

        S_RD_UC_WAIT:
          begin
            nstat = dev_rvalid ? S_RD_RESP : S_RD_UC_WAIT;
          end

        S_RD_RESP:
          begin
            nstat = S_IDLE;
          end

        S_WR_LOOKUP:
          begin
            nstat = dev_wrdy ? S_WR_BUS_WAIT : S_WR_BUS_REQ;
          end

        S_WR_BUS_REQ:
          begin
            nstat = dev_wrdy ? S_WR_BUS_WAIT : S_WR_BUS_REQ;
          end

        // dev_wrdy is reused here in the same way as the original
        // no-cache implementation: after cpu_wen has been dropped,
        // wait until the write side is ready again, then report wresp.
        S_WR_BUS_WAIT:
          begin
            nstat = dev_wrdy ? S_WR_RESP : S_WR_BUS_WAIT;
          end

        S_WR_RESP:
          begin
            nstat = S_IDLE;
          end

        default:
          begin
            nstat = S_IDLE;
          end
      endcase
    end

  // Output logic. data_valid/data_wresp are asserted only in dedicated
  // response states, so each response lasts exactly one cycle.
  always @(*)
    begin
      data_valid = 1'b0;
      data_rdata = resp_rdata;
      data_wresp = 1'b0;

      cpu_ren    = 4'h0;
      cpu_raddr  = 32'h0;

      cpu_wen    = 4'h0;
      cpu_waddr  = op_addr;
      cpu_wdata  = op_wdata;

      case (state)
        S_RD_LOOKUP:
          begin
            if (!hit_r && dev_rrdy)
              begin
                cpu_ren   = 4'hF;
                cpu_raddr = {op_addr[31:4], 4'b0000};
              end
            else
              begin
                cpu_raddr = {op_addr[31:4], 4'b0000};
              end
          end

        S_RD_MISS_REQ:
          begin
            if (dev_rrdy)
              begin
                cpu_ren = 4'hF;
              end
            cpu_raddr = {op_addr[31:4], 4'b0000};
          end

        S_RD_MISS_WAIT:
          begin
            cpu_raddr = {op_addr[31:4], 4'b0000};
          end

        S_RD_UC_REQ:
          begin
            if (dev_rrdy)
              begin
                cpu_ren = op_ren;
              end
            cpu_raddr = op_addr;
          end

        S_RD_UC_WAIT:
          begin
            cpu_raddr = op_addr;
          end

        S_RD_RESP:
          begin
            data_valid = 1'b1;
            data_rdata = resp_rdata;
          end

        S_WR_LOOKUP:
          begin
            if (dev_wrdy)
              begin
                cpu_wen = op_wen;
              end
            cpu_waddr = op_addr;
            cpu_wdata = op_wdata;
          end

        S_WR_BUS_REQ:
          begin
            if (dev_wrdy)
              begin
                cpu_wen = op_wen;
              end
            cpu_waddr = op_addr;
            cpu_wdata = op_wdata;
          end

        S_WR_BUS_WAIT:
          begin
            cpu_wen   = 4'h0;
            cpu_waddr = op_addr;
            cpu_wdata = op_wdata;
          end

        S_WR_RESP:
          begin
            data_wresp = 1'b1;
            cpu_wen    = 4'h0;
            cpu_waddr  = op_addr;
            cpu_wdata  = op_wdata;
          end

        default:
          begin
            data_valid = 1'b0;
            data_wresp = 1'b0;
            cpu_ren    = 4'h0;
            cpu_wen    = 4'h0;
          end
      endcase
    end

  /******** 不要修改以下代码 ********/
`else

  localparam R_IDLE  = 2'b00;
  localparam R_STAT0 = 2'b01;
  localparam R_STAT1 = 2'b11;
  reg [1:0] r_state, r_nstat;
  reg [3:0] ren_r;

  always @(posedge cpu_clk or posedge cpu_rst)
    begin
      r_state <= cpu_rst ? R_IDLE : r_nstat;
    end

  always @(*)
    begin
      case (r_state)
        R_IDLE:
          r_nstat = (|data_ren) ? (dev_rrdy ? R_STAT1 : R_STAT0) : R_IDLE;
        R_STAT0:
          r_nstat = dev_rrdy ? R_STAT1 : R_STAT0;
        R_STAT1:
          r_nstat = dev_rvalid ? R_IDLE : R_STAT1;
        default:
          r_nstat = R_IDLE;
      endcase
    end

  always @(posedge cpu_clk or posedge cpu_rst)
    begin
      if (cpu_rst)
        begin
          data_valid <= 1'b0;
          cpu_ren    <= 4'h0;
        end
      else
        begin
          case (r_state)
            R_IDLE:
              begin
                data_valid <= 1'b0;

                if (|data_ren)
                  begin
                    if (dev_rrdy)
                      cpu_ren <= data_ren;
                    else
                      ren_r   <= data_ren;

                    cpu_raddr <= data_addr;
                  end
                else
                  cpu_ren   <= 4'h0;
              end
            R_STAT0:
              begin
                cpu_ren    <= dev_rrdy ? ren_r : 4'h0;
              end
            R_STAT1:
              begin
                cpu_ren    <= 4'h0;
                data_valid <= dev_rvalid ? 1'b1 : 1'b0;
                data_rdata <= dev_rvalid ? dev_rdata : 32'h0;
              end
            default:
              begin
                data_valid <= 1'b0;
                cpu_ren    <= 4'h0;
              end
          endcase
        end
    end

  localparam W_IDLE  = 2'b00;
  localparam W_STAT0 = 2'b01;
  localparam W_STAT1 = 2'b11;
  reg  [1:0] w_state, w_nstat;
  reg  [3:0] wen_r;
  wire       wr_resp = dev_wrdy & (cpu_wen == 4'h0) ? 1'b1 : 1'b0;

  always @(posedge cpu_clk or posedge cpu_rst)
    begin
      w_state <= cpu_rst ? W_IDLE : w_nstat;
    end

  always @(*)
    begin
      case (w_state)
        W_IDLE:
          w_nstat = (|data_wen) ? (dev_wrdy ? W_STAT1 : W_STAT0) : W_IDLE;
        W_STAT0:
          w_nstat = dev_wrdy ? W_STAT1 : W_STAT0;
        W_STAT1:
          w_nstat = wr_resp ? W_IDLE : W_STAT1;
        default:
          w_nstat = W_IDLE;
      endcase
    end

  always @(posedge cpu_clk or posedge cpu_rst)
    begin
      if (cpu_rst)
        begin
          data_wresp <= 1'b0;
          cpu_wen    <= 4'h0;
        end
      else
        begin
          case (w_state)
            W_IDLE:
              begin
                data_wresp <= 1'b0;

                if (|data_wen)
                  begin
                    if (dev_wrdy)
                      cpu_wen <= data_wen;
                    else
                      wen_r   <= data_wen;

                    cpu_waddr  <= data_addr;
                    cpu_wdata  <= data_wdata;
                  end
                else
                  cpu_wen    <= 4'h0;
              end
            W_STAT0:
              begin
                cpu_wen    <= dev_wrdy ? wen_r : 4'h0;
              end
            W_STAT1:
              begin
                cpu_wen    <= 4'h0;
                data_wresp <= wr_resp ? 1'b1 : 1'b0;
              end
            default:
              begin
                data_wresp <= 1'b0;
                cpu_wen    <= 4'h0;
              end
          endcase
        end
    end

`endif

endmodule
