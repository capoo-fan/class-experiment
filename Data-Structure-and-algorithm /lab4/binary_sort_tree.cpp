#include <stdio.h>
#include <stdlib.h>

typedef struct TreeNode
{
    int val;
    struct TreeNode *left;
    struct TreeNode *right;
} TreeNode;

TreeNode *createNode(int val)
{
    TreeNode *newNode = (TreeNode *)malloc(sizeof(TreeNode));
    newNode->val = val;
    newNode->left = NULL;
    newNode->right = NULL;
    return newNode;
}

TreeNode *tree_insert(TreeNode *root, int num)
{
    if (root == NULL)
    {
        return createNode(num);
    }
    int val = root->val;
    if (num == val)
        return root; // 节点已经存在
    if (num < val)
        root->left = tree_insert(root->left, num);
    else
        root->right = tree_insert(root->right, num);
    return root;
}

TreeNode *find_min(TreeNode *root) // 找到子树的最小值
{
    while (root && root->left != NULL)
    {
        root = root->left;
    }
    return root;
}

TreeNode *tree_delete(TreeNode *root, int num)
{
    if (root == NULL)
        return NULL;
    int val = root->val;
    if (val == num)
    {
        TreeNode *left = root->left;
        TreeNode *right = root->right;
        if (left == NULL)
        {
            free(root);
            return right;
        }
        else if (right == NULL)
        {
            free(root);
            return left;
        }
        else
        {
            // 两个子节点都在
            TreeNode *temp = find_min(root->right);
            root->val = temp->val;
            root->right = tree_delete(root->right, temp->val);
        }
    }
    else
    {
        if (val > num)
            root->left = tree_delete(root->left, num);
        else
            root->right = tree_delete(root->right, num);
    }
    return root;
}

TreeNode *query(TreeNode *root, int left, int right)
{
    if (root == NULL)
        return NULL; // 找不到
    int val = root->val;
    if (left <= val && val <= right)
        return root;
    else if (val < left)
        return query(root->right, left, right);
    else if (right < val)
        return query(root->left, left, right);
    return NULL;
}

int main()
{
    int n;
    scanf("%d", &n);
    TreeNode *root = NULL;
    for (int i = 0; i < n; i++)
    {
        char c;
        scanf(" %c", &c);
        if (c == 'I')
        {
            int num;
            scanf("%d", &num);
            root = tree_insert(root, num);
        }
        else if (c == 'D')
        {
            int num;
            scanf("%d", &num);
            root = tree_delete(root, num);
        }
        else
        {
            int left, right;
            scanf("%d %d", &left, &right);
            TreeNode *ansNode = query(root, left, right);
            if (ansNode != NULL)
                printf("%d\n", ansNode->val);
            else
                printf("\n");
        }
    }
}