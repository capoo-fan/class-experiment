#include <stdio.h>
#include <stdlib.h>

typedef int ElemType;

typedef struct
{
    ElemType *elem; // 空间基地址，空间存放纸牌正反面状态值,正/反分别用1/0表示
    int length;     // 存放纸牌数
    int listsize;   // 存放空间的容量
} SqList;

void init(SqList *L, int n)
{
    L->elem = (ElemType *)malloc(n * sizeof(ElemType));
    for (int i = 0; i < n; i++)
        L->elem[i] = 1;
    L->length = n;
    L->listsize = n;
}

void game(SqList *L)
{
    for (int i = 2; i <= L->length; i++)
    {
        for (int j = 0; j < L->length; j++)
        {
            if ((j + 1) % i == 0)
                L->elem[j] = ~L->elem[j];
        }
    }
    int sum = 0;
    for (int i = 0; i < L->length; i++)
    {
        if (L->elem[i] == 1)
        {
            sum++;
            printf("%d ", i + 1);
        }
    }
    printf("\n");
    printf("%d", sum);
}

int main()
{
    SqList L;
    int n;
    scanf("%d", &n);
    init(&L, n);
    game(&L);
    return 0;
}