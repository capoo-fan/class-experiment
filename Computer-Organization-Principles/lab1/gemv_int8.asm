.data
    Result_C:   .space 16                       # result vector (4 x 32bit)

    Matrix_A:   .byte 1, 2, 3, 4, 5, 6, 7, 8    # matrix A (4 x 8)
                .byte 2, 3, 4, 5, 6, 7, 8, 9
                .byte 3, 4, 5, 6, 7, 8, 9, 10
                .byte 4, 5, 6, 7, 8, 9, 10, 11

    Vector_B:   .byte 1, 1, 1, 1, 1, 1, 1, 1    # Vector B (8 x 1)

    space   :   .asciz " "

.macro push %a
    addi sp, sp, -4
    sw   %a, 0(sp)
.end_macro

.macro pop %a
    lw   %a, 0(sp)
    addi sp, sp, 4
.end_macro

.text
MAIN:
    ori   sp, zero, 0
    
    lui   a2, 0x10010       
    addi  a0, a2, 16       
    addi  a1, a2, 48      
    addi  a3, zero, 4       
    addi  a4, zero, 8      
  

    # Call Sub-routine
    jal   ra, MATMUL_INT8

    lui   a0, 0x10010       # a0 = Address of C
    ori   a1, zero, 4       # a1 = dimD = 4
    jal   ra, PRINT_VEC

    ori   a7, zero, 10
    ecall                   # MAIN ends here
    
# Sub-Routine: Print a Vector
#   a0: Address of Vector
#   a1: Length of Vector
PRINT_VEC:
    ori   t0, zero, 0       # t0 - Loop index i
    ori   t1, a0, 0         # t1 - Address of Elements
    
PRINT_LOOP:    
    lh    a0, 0(t1)         # t2 = Vec[i]
    ori   a7, zero, 1       # a7 = 1 (print integer syscall no.)
    ecall
    
    # Print the Space
    la    a0, space
    ori   a7, zero, 4       # a7 = 4 (print string syscall no.)
    ecall
    
    addi  t0, t0, 1         # i++
    addi  t1, t1, 4         # t1 += 4
    blt   t0, a1, PRINT_LOOP

    jalr  zero, 0(ra)
    


# Sub-Routine: Matrix Multiplication
#   a0: xxx parameter
#   a1: ...

#   ...
MATMUL_INT8:
    # --- 1. 现场保护 ---
    push ra             # 保存返回地址
    push s0          

    add   t0, zero, zero    # t0 = i = 0 
    add   t2, a0, zero      # t2 = Matrix_A 的当前元素指针
    add   a5, a2, zero      # a5 = Result_C 的当前元素指针 

ROW_LOOP:
    bge   t0, a3, MATMUL_END # 如果 i >= 4，结束循环
    
    add   t1, zero, zero    
    add   t3, a1, zero     
    add   t4, zero, zero    

COL_LOOP:
    bge   t1, a4, COL_END   # 如果 j >= 8
    
    lb    t5, 0(t2)         # 加载 A[i][j] 
    lb    t6, 0(t3)         # 加载 B[j] 
    
    mul   t5, t5, t6        # t5 = A[i][j] * B[j]
    add   t4, t4, t5        # 累加
    
    addi  t2, t2, 1         # A 的指针移动到下一个字节
    addi  t3, t3, 1         # B 的指针移动到下一个字节
    addi  t1, t1, 1         # j++
    
    jal   zero, COL_LOOP    

COL_END:
    sw    t4, 0(a5)         # 将结果存入 C[i]
    addi  a5, a5, 4         # 指针移动
    addi  t0, t0, 1         # i++
    
    jal   zero, ROW_LOOP    # 无条件跳转回 ROW_LOOP

MATMUL_END:
    # --- 2. 现场恢复 ---
    pop s0              # 恢复寄存器
    pop ra              # 恢复返回地址
    
    jalr  zero, 0(ra)   # 子程序返回