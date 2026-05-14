#include <cstring>
#include <stdio.h>
#include <stdlib.h>
#define max_m 50
#define max_n 50
int m, n;
int ans = 0;
int graph[max_m][max_n];
int visited[max_m][max_n];
int dx[] = {1, 0, -1, 0};
int dy[] = {0, 1, 0, -1};
void dfs(int x, int y)
{
    if (x == m - 1 && y == n - 1)
    {
        ans++;
        return;
    }
    for (int i = 0; i < 4; i++)
    {
        int nx = x + dx[i];
        int ny = y + dy[i];
        if (nx >= 0 && nx < m && ny >= 0 && ny < n && graph[nx][ny] != 1 && !visited[nx][ny])
        {
            visited[nx][ny] = 1;
            dfs(nx, ny);
            visited[nx][ny] = 0;
        }
    }
}
int main()
{

    scanf("%d %d", &m, &n);
    for (int i = 0; i < m; i++)
        for (int j = 0; j < n; j++)
            scanf("%d", &graph[i][j]);
    memset(visited, 0, sizeof(visited));
    if (graph[0][0] == 1 || graph[n - 1][m - 1] == 1)
    {
        printf("0");
        return 0;
    }
    if (m == 1 && n == 1)
    {
        printf("1");
        return 0;
    }

    visited[0][0] = 1;
    dfs(0, 0);
    printf("%d", ans);
    return 0;
}