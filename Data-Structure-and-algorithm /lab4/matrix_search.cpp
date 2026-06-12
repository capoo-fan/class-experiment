#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

bool searchMatrix(int **matrix, int matrixRowSize, int matrixColSize, int target)
{
    int row = 0, col = matrixColSize - 1;
    while (row < matrixRowSize && col >= 0)
    {
        if (matrix[row][col] == target)
        {
            return true;
        }
        else if (matrix[row][col] > target)
            col--;
        else
            row++;
    }
    return false;
}

int main()
{
    int m, n;
    scanf("%d %d", &m, &n);

    // 动态分配二维数组
    int **matrix = (int **)malloc(m * sizeof(int *));
    for (int i = 0; i < m; i++)
    {
        matrix[i] = (int *)malloc(n * sizeof(int));
        for (int j = 0; j < n; j++)
        {
            scanf("%d", &matrix[i][j]);
        }
    }

    int K;
    scanf("%d", &K);
    for (int i = 0; i < K; i++)
    {
        int target;
        scanf("%d", &target);

        bool found = searchMatrix(matrix, m, n, target);
        printf("%s\n", found ? "true" : "false");
    }

    // 释放内存
    for (int i = 0; i < m; i++)
    {
        free(matrix[i]);
    }
    free(matrix);

    return 0;
}