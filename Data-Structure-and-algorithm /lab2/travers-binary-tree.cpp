#include <stdio.h>
#include <stdlib.h>

struct TreeNode
{
    int val;
    struct TreeNode *left;
    struct TreeNode *right;
};

struct TreeNode *buildTree(int *preorder, int preordersize, int *inorder, int inordersize)
{
    if (preordersize == 0 || inordersize == 0)
    {
        return NULL;
    }

    struct TreeNode *root = (struct TreeNode *)malloc(sizeof(struct TreeNode));
    root->val = preorder[0];
    root->left = NULL;
    root->right = NULL;

    int rootindex;
    for (int i = 0; i < inordersize; i++)
    {
        if (inorder[i] == preorder[0])
        {
            rootindex = i;
            break;
        }
    }
    int leftsize = rootindex;

    int rightsize = inordersize - rootindex - 1;

    root->left = buildTree(preorder + 1, leftsize, inorder, leftsize);
    root->right = buildTree(preorder + 1 + leftsize, rightsize, inorder + rootindex + 1, rightsize);

    return root;
}

void printTree(struct TreeNode *root)
{
    if (root == NULL)
    {
        return;
    }

    struct TreeNode **queue = (struct TreeNode **)malloc(sizeof(struct TreeNode *) * 1000);
    int head = 0;
    int tail = 0;

    queue[tail++] = root;

    while (head < tail)
    {
        struct TreeNode *node = queue[head++];

        if (node != NULL)
        {
            printf("%d ", node->val);
            queue[tail++] = node->left;
            queue[tail++] = node->right;
        }
        else
        {
            printf("null ");
        }
    }
    free(queue);
}

int main()
{
    int preorderSize;
    scanf("%d", &preorderSize);
    int *preorder = (int *)malloc(preorderSize * sizeof(int));
    for (int i = 0; i < preorderSize; i++)
    {
        scanf("%d", &preorder[i]);
    }

    int inorderSize = preorderSize;
    int *inorder = (int *)malloc(inorderSize * sizeof(int));
    for (int i = 0; i < inorderSize; i++)
    {
        scanf("%d", &inorder[i]);
    }

    struct TreeNode *root = buildTree(preorder, preorderSize, inorder, inorderSize);
    printTree(root);

    return 0;
}