#include <cstring>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#define edge 300
#define max_c 600
int main()
{
    int n, m, c; // 顶点数，边数，成本上限
    scanf("%d %d %d", &n, &m, &c);
    int s, t; // 起点和终点
    scanf("%d %d", &s, &t);
    int value[edge], graph[edge][edge];
    memset(graph, -1, sizeof(graph));
    for (int i = 1; i <= n; i++)
        scanf("%d", &value[i]);
    for (int i = 0; i < m; i++)
    {
        int u, v, w;
        scanf("%d %d %d", &u, &v, &w);
        graph[u][v] = w;
    }
    int dp[edge][max_c]; // dp[i][j]表示从s到i，成本不超过j的最大价值
   
}