#include <stdio.h>
#include <stdlib.h>

struct TreeNode
{
    int val;
    int color; // 0 蓝色，1 红色
    struct TreeNode *left;
    struct TreeNode *right;
};

/******************* 染色 *******************/
int getNumber(struct TreeNode *root, int **ops, int opsSize)
{
    int row = opsSize, col = 3;
    int sum = 0; // 记录红色数量
    for (int i = 0; i < row; i++)
    {
        int type = ops[i][0], x = ops[i][1], y = ops[i][2];
        struct TreeNode **queue = (struct TreeNode **)malloc(sizeof(struct TreeNode *) * 1000);
        int head = 0, tail = 0;
        queue[tail++] = root;
        while (head < tail)
        {
            struct TreeNode *node = queue[head++];
            int val = node->val;
            if (val >= x && val <= y)
            {
                if (type == 1 && node->color == 0)
                {
                    node->color = 1; // 染红
                    sum++;
                }
                else if (type == 0 && node->color == 1)
                {
                    node->color = 0; // 染黑
                    sum--;
                }
            }
            if (node->left != NULL)
                queue[tail++] = node->left;
            if (node->right != NULL)
                queue[tail++] = node->right;
        }
        free(queue);
    }
    return sum;
}
/*****************************************************/

/******************* 读取数据 *******************/
struct TreeNode *newTreeNode(int val)
{
    struct TreeNode *node = (struct TreeNode *)malloc(sizeof(struct TreeNode));
    node->val = val;
    node->color = 0;
    node->left = node->right = NULL;
    return node;
}

struct TreeNode *constructTree(int size)
{
    if (size == 0)
        return NULL;

    struct TreeNode **nodes = (struct TreeNode **)malloc(size * sizeof(struct TreeNode *));
    for (int i = 0; i < size; i++)
    {
        int val;
        scanf("%d", &val);
        if (val == -1)
        {
            nodes[i] = NULL;
        }
        else
        {
            nodes[i] = newTreeNode(val);
        }
    }

    for (int i = 0, j = 1; j < size; i++)
    {
        if (nodes[i] != NULL)
        {
            if (j < size)
                nodes[i]->left = nodes[j++];
            if (j < size)
                nodes[i]->right = nodes[j++];
        }
    }

    struct TreeNode *root = nodes[0];
    free(nodes);
    return root;
}

void readOps(int ***ops, int *opsSize)
{
    scanf("%d", opsSize);

    *ops = (int **)malloc(*opsSize * sizeof(int *));
    while (getchar() != '[')
    {
    }
    for (int i = 0; i < *opsSize; i++)
    {
        (*ops)[i] = (int *)malloc(3 * sizeof(int));
        while (getchar() != '[')
        {
        }
        for (int j = 0; j < 3; j++)
        {
            scanf("%d", &((*ops)[i][j]));
        }
        while (getchar() != ']')
        {
        }
    }
}
/*****************************************************/

int main()
{
    int nodeSize;
    scanf("%d", &nodeSize);
    struct TreeNode *root = constructTree(nodeSize);
    int **ops, opsSize;
    readOps(&ops, &opsSize);
    int result = getNumber(root, ops, opsSize);
    printf("%d", result);
    return 0;
}