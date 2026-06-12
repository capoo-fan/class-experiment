#include <stdio.h>
#include <stdlib.h>
#define max_node 300
#define max_c 600

typedef struct node
{
    int next_node;
    int w; // 边的代价
    struct node *next;
} node;

node *head[max_node];

void add_edge(int u, int v, int w)
{
    node *new_node = (node *)malloc(sizeof(node));
    new_node->next_node = v;
    new_node->w = w;
    new_node->next = head[u];
    head[u] = new_node;
}

int max(int a, int b)
{
    return a > b ? a : b;
}
int main()
{
    int n, m, c; // 顶点数，边数，成本上限
    scanf("%d %d %d", &n, &m, &c);
    int s, t; // 起点和终点
    scanf("%d %d", &s, &t);
    int value[max_node];
    for (int i = 1; i <= n; i++)
    {
        scanf("%d", &value[i]);
        head[i] = NULL;
    }

    for (int i = 0; i < m; i++)
    {
        int u, v, w;
        scanf("%d %d %d", &u, &v, &w);
        add_edge(u, v, w);
    }

    int dp[max_node][max_c];
    for (int i = 1; i <= n; i++)
        for (int j = 0; j <= c; j++)
            dp[i][j] = -1; //-1表示不可达

    int queue[max_node];
    int front = 0, tail = 0;
    dp[s][0] = value[s]; // s 自己走到自己
    queue[tail++] = s;
    while (front < tail)
    {
        int u = queue[front++];
        for (int cost = 0; cost <= c; cost++)
        {
            if (dp[u][cost] != -1)
            {
                for (node *e = head[u]; e != NULL; e = e->next)
                {
                    int v = e->next_node;
                    int w = e->w;
                    if (cost + w <= c)
                        dp[v][cost + w] = max(dp[v][cost + w], dp[u][cost] + value[v]);
                }
            }
        }
        for (node *e = head[u]; e != NULL; e = e->next)
            queue[tail++] = e->next_node;
    }
    int ans = -1;
    for (int cost = 0; cost <= c; cost++)
        ans = max(ans, dp[t][cost]);
    if (ans == -1)
        printf("-1");
    else
        printf("%d", ans);
}