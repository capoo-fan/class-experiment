#include <cstring>
#include <stdio.h>
#include <stdlib.h>
#define max_n 500
#define max_C 500
int max(int a, int b)
{
    return a > b ? a : b;
}
int main()
{
    int C, n;
    scanf("%d %d", &C, &n); // 采药的时间和草药的数目
    int time[max_n];
    int value[max_n];
    for (int i = 1; i <= n; i++)
        scanf("%d %d", &time[i], &value[i]);
    int dp[max_n][max_C]; // 前 n 件物品，选取重量不超过 C 的最大价值
    memset(dp, 0, sizeof(dp));
    for (int i = 1; i <= n; i++)
    {
        for (int t = 0; t <= C; t++)
        {
            if (t >= time[i])
            {
                dp[i][t] = max(dp[i][t - time[i]] + value[i], dp[i - 1][t]);
            }
            else
            {
                dp[i][t] = dp[i - 1][t];
            }
        }
    }
    printf("%d", dp[n][C]);
    return 0;
}