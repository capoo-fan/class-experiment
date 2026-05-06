#include <stdio.h>
#include <stdint.h> 

#define DIM_D 4     // 矩阵行数     
#define DIM_N 8     // 矩阵列数/向量长度

int32_t Result_C[DIM_D];        
int8_t  Matrix_A[DIM_D*DIM_N] = {1, 2, 3, 4, 5, 6, 7, 8,
                                 2, 3, 4, 5, 6, 7, 8, 9,
                                 3, 4, 5, 6, 7, 8, 9, 10,
                                 4, 5, 6, 7, 8, 9, 10, 11};
int8_t  Vector_B[DIM_N] = {1, 1, 1, 1, 1, 1, 1, 1};

void matmul_int8(int32_t* C, int8_t* A, int8_t* B, int dimD, int dimN)
{
    __asm__ volatile (
        "add   t0, zero, zero          \n\t" 
        "add   t2, %[A], zero          \n\t" // t2 = Matrix_A 的指针
        "add   a5, %[C], zero          \n\t" // a5 = Result_C 的指针 

        "ROW_LOOP_%=:                  \n\t"
        "bge   t0, %[dimD], MATMUL_END_%=\n\t"
        
        "add   t1, zero, zero          \n\t"
        "add   t3, %[B], zero          \n\t" // t3 = Vector_B 的当前元素指针     
        "add   t4, zero, zero          \n\t" 

        "COL_LOOP_%=:                  \n\t"
        "bge   t1, %[dimN], COL_END_%= \n\t"
        
        "lw    t5, 0(t2)               \n\t" // 加载 A 的 4 个字节到 t5
        "lw    t6, 0(t3)               \n\t" // 加载 B 的 4 个字节到 t6
        
        ".insn r 0x0B, 0x0, 0x00, t4, t5, t6 \n\t" 
        
        "addi  t2, t2, 4               \n\t" // A 的指针移动 4 个字节
        "addi  t3, t3, 4               \n\t" // B 的指针移动 4 个字节
        "addi  t1, t1, 4               \n\t" // j += 4 (内层循环步长改为4)
        
        "jal   zero, COL_LOOP_%=       \n\t" // 无条件跳转回 COL_LOOP

        "COL_END_%=:                   \n\t"
        "sw    t4, 0(a5)               \n\t" // 将结果存入 C[i]
        "addi  a5, a5, 4               \n\t" 
        "addi  t0, t0, 1               \n\t" // i++
        
        "jal   zero, ROW_LOOP_%=       \n\t" // 无条件跳转回 ROW_LOOP

        "MATMUL_END_%=:                \n\t" 

        : // 输出操作数
        : [C] "r" (C), [A] "r" (A), [B] "r" (B), [dimD] "r" (dimD), [dimN] "r" (dimN)
        : "t0", "t1", "t2", "t3", "t4", "t5", "t6", "a5", "memory" 
    );
}

int main()
{
    matmul_int8(Result_C, Matrix_A, Vector_B, DIM_D, DIM_N);

    for (int i = 0; i < DIM_D; i++)
        printf("%d ", Result_C[i]);     

    printf("\n");

    return 0;
}