#include <math.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct
{
    int index;      // 编号保证排序
    int number;     // 初始数值
    int map_number; // 映射数值
} Element;

int cmp(const void *a, const void *b)
{
    Element *e1 = (Element *)a;
    Element *e2 = (Element *)b;

    if (e1->map_number == e2->map_number)
        return e1->index > e2->index;
    else
        return e1->map_number > e2->map_number;
}

/******************* 排序 *******************/
void sortJumbled(int *mapping, int *nums, int numsSize)
{
    int *res_nums = (int *)malloc(numsSize * sizeof(int));
    Element *element = (Element *)malloc(numsSize * sizeof(Element));
    for (int i = 0; i < numsSize; i++)
    {
        element[i].index = i;
        // 处理映射值
        int num = nums[i];
        int map_num = 0;
        int cnt = 0;
        if (num == 0)
        {
            element[i].number = nums[i];
            element[i].map_number = mapping[0];
        }
        else
        {
            while (num != 0)
            {
                int t = num % 10;
                map_num += pow(10, cnt) * mapping[t];
                num /= 10;
                cnt++;
            }
            element[i].number = nums[i];
            element[i].map_number = map_num;
        }
    }

    qsort(element, numsSize, sizeof(Element), cmp);

    for (int i = 0; i < numsSize; i++)
        printf("%d ", element[i].number);
    printf("\n");
    free(element);
}
/*****************************************************/

/******************* 读取数据 *******************/
void readInput(int **mapping, int **nums, int *numsSize)
{
    scanf("%d", numsSize);

    *mapping = (int *)malloc(10 * sizeof(int));
    for (int i = 0; i < 10; i++)
    {
        scanf("%d", &((*mapping)[i]));
    }

    *nums = (int *)malloc((*numsSize) * sizeof(int));
    for (int i = 0; i < *numsSize; i++)
    {
        scanf("%d", &((*nums)[i]));
    }
}
/*****************************************************/

int main()
{
    int *mapping, *nums, numsSize;
    readInput(&mapping, &nums, &numsSize);
    sortJumbled(mapping, nums, numsSize);

    return 0;
}