#!/bin/sh

main=$(grep -l "main[[:space:]]*(" *.c 2>/dev/null)
base=$(basename "$main" .c)

cat > startup.h << 'EOF'
#ifndef STARTUP_H
#define STARTUP_H

__attribute__((naked)) void _start() {
    asm volatile (
        "lui sp, %hi(_stack_top)\n"  // 设置堆栈指针到 RAM 顶部
        "addi sp, sp, %lo(_stack_top)\n"
        "call main\n"
        "1: j 1b\n"  // 无限循环
    );
}

#ifndef C_TEST
#include <stddef.h>
extern char _heap_start;
extern char _stack_top[];
void* _sbrk(ptrdiff_t incr)
{
    static char* heap_end = &_heap_start;
    char* prev_heap_end = heap_end;
    char* stack_pointer;

    // 检查堆栈是否碰撞
    asm volatile ("mv %0, sp" : "=r"(stack_pointer));
    if (heap_end + incr > stack_pointer) return (void*)-1;

    heap_end += incr;
    return (void*)prev_heap_end;
}
#endif
#endif
EOF

echo '#include "startup.h"' > temp_main.c
cat "$main" >> temp_main.c

cat << EOF > link.ld
MEMORY
{
    rom  : ORIGIN = 0x00000000, LENGTH = 160K  /* IROM: .text */
    ram  : ORIGIN = 0x80000000, LENGTH = 280K  /* DRAM: .data, .rodata, etc. */
    sram : ORIGIN = 0x80080000, LENGTH = 2M   /* HEAP and STACK */
}

SECTIONS
{
    /* 代码段：放置在 ROM 开头 */
    .text : {
        *(.text)
        *(.text.*)
        _etext = .;     /* 代码段结束标记，用于复制 .data */
    } > rom

    /* 只读数据段：放在 RAM */
    .rodata : {
        *(.rodata)
        *(.rodata.*)
    } > ram

    /* 数据段 */
    .data : {
        _data_start = .;
        *(.data)
        *(.data.*)
        _data_end = .;
    } > ram

    /* BSS 段：零初始化，在 RAM 中 */
    .bss : {
        _bss_start = .;
        *(.bss)
        *(.bss.*)
        *(COMMON)
        _bss_end = .;
    } > ram

    _end = .; /* 标记初始数据的结束 */
    _heap_start = ORIGIN(sram); /* 堆的起始地址 */
    _stack_top = ORIGIN(sram) + LENGTH(sram); /* 栈底 */
}
EOF

riscv32-unknown-elf-gcc -T link.ld \
                        -nostartfiles -fno-builtin -mabi=ilp32 -march=rv32im \
                        -o "$base" temp_main.c peripheral.c -lm
rm startup.h temp_main.c link.ld

if [ ! -e "$base" ]; then
    echo "Compile Failed"
    exit 1
fi

riscv32-unknown-elf-objdump -d -M no-aliases -j .text -j .data -j .rodata "$base" > "$base.s"
riscv32-unknown-elf-objcopy -O verilog "$base" "$base.hex"
rm "$base"

awk -v base="$base" '
# 处理一个已收集的字节数据块
# - bytes: 包含连续十六进制数字的字符串
# - outfile: 目标文件名
function process_block(bytes, outfile) {
    # 以8个字符（4个字节）为步长遍历整个字符串
    for (i = 1; i <= length(bytes); i += 8) {
        # 提取一个32位的字（8个十六进制字符）
        chunk = substr(bytes, i, 8)
        
        # 确保我们处理的是一个完整的字
        if (length(chunk) < 8) continue

        # 从块中提取4个独立的字节
        b1 = substr(chunk, 1, 2)
        b2 = substr(chunk, 3, 2)
        b3 = substr(chunk, 5, 2)
        b4 = substr(chunk, 7, 2)

        # 按小端顺序 (B4 B3 B2 B1) 格式化并追加到输出文件
        printf "%s%s%s%s\n", b4, b3, b2, b1 >> outfile
    }
}

# 读取任何输入行之前执行一次
BEGIN {
    # 初始化状态变量
    current_addr = -1        # 当前地址块的起始地址
    section = "none"         # "A"-代码段, "B"-数据段
    collected_bytes = ""     # 当前区域的字节数据

    print "memory_initialization_radix=16;\nmemory_initialization_vector=" > base "_text.coe"; close(base "_text.coe")
    print "memory_initialization_radix=16;\nmemory_initialization_vector=" > base "_data.coe"; close(base "_data.coe")
}

# 主处理块: 对输入文件的每一行执行
{
    # 判断是否为地址行 (以 @ 开头)
    if ($0 ~ /^@/) {
        # 如果之前已经收集了数据，说明一个地址块结束了，需要先处理它
        if (current_addr != -1 && length(collected_bytes) > 0) {
            
            # 对数据段的特殊填充逻辑：根据地址差进行填充
            if (section == "B") {
                next_addr = strtonum("0x" substr($0, 2))
                addr_diff_bytes = next_addr - current_addr
                collected_bytes_count = length(collected_bytes) / 2

                # 如果收集的字节数小于地址差，用 "00" 补齐
                if (addr_diff_bytes > collected_bytes_count) {
                    pad_bytes = addr_diff_bytes - collected_bytes_count
                    for (i = 1; i <= pad_bytes; i++) {
                        collected_bytes = collected_bytes "00"
                    }
                }
            }
            
            # 处理完成填充的区块
            if (section == "A") process_block(collected_bytes, base "_text.coe")
            if (section == "B") process_block(collected_bytes, base "_data.coe")
        }

        # 为新的地址块更新状态
        current_addr = strtonum("0x" substr($0, 2))
        collected_bytes = "" # 重置字节收集器

        if (current_addr == 0) {
            section = "A"
        } else if (current_addr >= 0x80000000) {
            section = "B"
        } else {
            section = "none" # 忽略其他地址区域
        }
    } else {
        # 如果是数据行
        # 移除所有空白字符 (空格, tab等)
        gsub(/[[:space:]]+/, "")
        # 将干净的十六进制数据追加到收集器
        if (section != "none") {
            collected_bytes = collected_bytes $0
        }
    }
}

# 处理完所有输入行后执行一次
END {
    # 处理文件中最后一个地址块剩余的数据
    if (current_addr != -1 && length(collected_bytes) > 0) {
        
        # 对数据段的最后一部分数据进行末尾填充，确保是4字节的整数倍
        if (section == "B") {
            collected_bytes_count = length(collected_bytes) / 2
            remainder = collected_bytes_count % 4
            if (remainder != 0) {
                pad_bytes = 4 - remainder
                for (i = 1; i <= pad_bytes; i++) {
                    collected_bytes = collected_bytes "00"
                }
            }
        }

        if (section == "A") process_block(collected_bytes, base "_text.coe")
        if (section == "B") process_block(collected_bytes, base "_data.coe")
    }
}
' "$base.hex"

rm "$base.hex"
