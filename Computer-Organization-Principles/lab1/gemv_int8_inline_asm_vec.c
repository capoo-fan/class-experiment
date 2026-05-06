#include <stdio.h>
#include <stdint.h> // 引入 stdint 以支持 int32_t, int8_t

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
    // __asm__ volatile 保证这段汇编不被编译器优化掉
    __asm__ volatile (
        "add   t0, zero, zero          \n\t" // t0 = i = 0 
        "add   t2, %[A], zero          \n\t" // t2 = Matrix_A 的当前元素指针
        "add   t7, %[C], zero          \n\t" // t7 = Result_C 的当前元素指针 

        "ROW_LOOP_%=:                  \n\t"
        "bge   t0, %[dimD], MATMUL_END_%=\n\t" // 如果 i >= dimD，结束循环
        
        "add   t1, zero, zero          \n\t" // t1 = j = 0
        "add   t3, %[B], zero          \n\t" // t3 = Vector_B 的当前元素指针     
        "add   t4, zero, zero          \n\t" // t4 = 累加器 sum = 0

        "COL_LOOP_%=:                  \n\t"
        "bge   t1, %[dimN], COL_END_%= \n\t" // 如果 j >= dimN，结束内层循环
        
        "lb    t5, 0(t2)               \n\t" // 加载 A[i][j] 
        "lb    t6, 0(t3)               \n\t" // 加载 B[j] 
        
        "mul   t5, t5, t6              \n\t" // t5 = A[i][j] * B[j]
        "add   t4, t4, t5              \n\t" // 累加 sum
        
        "addi  t2, t2, 1               \n\t" // A 的指针移动到下一个字节
        "addi  t3, t3, 1               \n\t" // B 的指针移动到下一个字节
        "addi  t1, t1, 1               \n\t" // j++
        
        "jal   zero, COL_LOOP_%=       \n\t" // 无条件跳转回 COL_LOOP (非伪指令)

        "COL_END_%=:                   \n\t"
        "sw    t4, 0(t7)               \n\t" // 将结果存入 C[i]
        "addi  t7, t7, 4               \n\t" // C的指针移动4字节(int32_t)
        "addi  t0, t0, 1               \n\t" // i++
        
        "jal   zero, ROW_LOOP_%=       \n\t" // 无条件跳转回 ROW_LOOP (非伪指令)

        "MATMUL_END_%=:                \n\t" // 结束块，正常滑入后续C代码

        : // 没有内联汇编直接映射的输出变量，我们通过 memory 和指针直接写回
        : [C] "r" (C), [A] "r" (A), [B] "r" (B), [dimD] "r" (dimD), [dimN] "r" (dimN) // 传入映射
        : "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7", "memory" // Clobber list声明使用的寄存器与内存修改
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