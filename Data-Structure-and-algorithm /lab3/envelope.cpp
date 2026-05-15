#include <stdio.h>
#include <stdlib.h>

// 信封结构体
typedef struct
{
    int width;
    int height;
} Envelope;

int cmp(const void *a, const void *b)
{
    // 将 void 指针转换为 Envelope 指针
    Envelope *e1 = (Envelope *)a;
    Envelope *e2 = (Envelope *)b;

    if (e1->width == e2->width)
        return e2->height - e1->height;
    return e1->width - e2->width;
}
int max(int a, int b)
{
    return a > b ? a : b;
}

int maxEnvelopes(Envelope *envelopes, int n)
{
    qsort(envelopes, n, sizeof(Envelope), cmp); // 找 h 的最长严格递增子序列
    int ans = 0;
    int *dp = (int *)malloc(n * sizeof(int));
    for (int i = 0; i < n; i++)
    {
        dp[i] = 1;
        for (int j = 0; j < i; j++)
        {
            int wi = envelopes[i].width, hi = envelopes[i].height;
            int wj = envelopes[j].width, hj = envelopes[j].height;
            if (hi > hj)
            {
                dp[i] = max(dp[i], dp[j] + 1);
            }
            ans = max(ans, dp[i]);
        }
    }
    return ans;
}

int main()
{
    int n;
    scanf("%d", &n);

    Envelope *envelopes = (Envelope *)malloc(n * sizeof(Envelope));
    for (int i = 0; i < n; i++)
    {
        scanf("%d %d", &envelopes[i].width, &envelopes[i].height);
    }

    int result = maxEnvelopes(envelopes, n);
    printf("%d\n", result);

    free(envelopes);
    return 0;
}