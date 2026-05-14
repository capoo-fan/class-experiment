#include <stdio.h>
#include <stdlib.h>

// 信封结构体
typedef struct
{
    int width;
    int height;
} Envelope;

int maxEnvelopes(Envelope *envelopes, int n)
{
    // TODO
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