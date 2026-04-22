#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct TreeNode
{
    int val;
    struct TreeNode *left;
    struct TreeNode *right;
};

struct TreeNode *buildTree()
{
    char str[50];
    if (scanf("%s", str) != 1)
        return NULL;
    if (strcmp(str, "#") == 0)
        return NULL;
    
    struct TreeNode *node = (struct TreeNode *)malloc(sizeof(struct TreeNode));
    node->val = atoi(str);
    // 中左右 前序遍历
    node->left = buildTree();
    node->right = buildTree();
    return node;
}

bool mirror(struct TreeNode *t1, struct TreeNode *t2)
{
    if (t1 == NULL && t2 == NULL)
        return true;
    if (t1 == NULL || t2 == NULL)
        return false;
    if(t1->val!=t2->val)
        return false;
    return mirror(t1->left, t2->right) && mirror(t1->right, t2->left); // 递归判断左右子树是否相等

}
int mirror_count(struct TreeNode *root)
{
    if (root == NULL)
        return 0;
    int count = 0;
    if(mirror(root->left, root->right))
        count++;
    count += mirror_count(root->left);
    count += mirror_count(root->right);
    return count;
}

int main()
{
    struct TreeNode *root = buildTree();
    int count = mirror_count(root);
    printf("%d", count);
    free(root);
    return 0;
}