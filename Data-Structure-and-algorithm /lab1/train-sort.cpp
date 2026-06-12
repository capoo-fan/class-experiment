#include <cstdio>
#include <stdio.h>
#include <stdlib.h>
int main()
{
    int a[1000], b[1000];
    int top_a = -1, top_b = -1;
    int val;
    char c;
    while (scanf("%d", &val) == 1)
    {
        a[++top_a] = val;
        c = getchar();
        if (c == '\n' || c == EOF)
            break;
    }
    while (scanf("%d", &val) == 1)
    {
        b[++top_b] = val;
        c = getchar();
        if (c == '\n' || c == EOF)
            break;
    }
    int q[1000];
    int pointer = -1;
    while (top_a >= 0 && top_b >= 0)
    {
        if (a[top_a] < b[top_b])
            q[++pointer] = a[top_a--];
        else
            q[++pointer] = b[top_b--];
    }
    while (top_a >= 0)
        q[++pointer] = a[top_a--];
    while (top_b >= 0)
        q[++pointer] = b[top_b--];
    for(int i=0; i<=pointer; i++)
        printf("%d ", q[i]);
    return 0;
}