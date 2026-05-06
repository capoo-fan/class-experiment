#include <stdio.h>  // 

#define DIM_D 4     // 矩阵行数     
#define DIM_N 8     // 矩阵列数/向量长度

int32_t Result_C[DIM_D];        // 
int8_t  Matrix_A[DIM_D*DIM_N] = {1, 2, 3, 4, 5, 6, 7, 8,
                                 2, 3, 4, 5, 6, 7, 8, 9,
                                 3, 4, 5, 6, 7, 8, 9, 10,
                                 4, 5, 6, 7, 8, 9, 10, 11};
int8_t  Vector_B[DIM_N] = {1, 1, 1, 1, 1, 1, 1, 1};

void matmul_int8(int32_t* C, int8_t* A, int8_t* B, int dimD, int dimN)
{
    for (int i = 0; i < dimD; i++)
    {
        int32_t sum = 0;
        for (int j = 0; j < dimN; j++)
            sum += A[i*dimN + j] * B[j];

        C[i] = sum;
    }
}

int main()
{
    matmul_int8(Result_C, Matrix_A, Vector_B, DIM_D, DIM_N);

    for (int i = 0; i < DIM_D; i++)
        printf("%d ", Result_C[i]);     // 

    printf("\n");

    return 0;
}