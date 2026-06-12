#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// 定义图书信息结构体
typedef struct
{
    char bookId[20]; // 书号
    char title[100]; // 书名
    char author[50]; // 作者
    int stock;       // 库存数量
} Book;

// 定义链表节点结构体
typedef struct Node
{
    Book book;
    struct Node *next;
} Node;

// 创建新节点
Node *CreateNode(Book book)
{
    Node *newbook = (Node *)malloc(sizeof(Node));
    newbook->book = book;
    newbook->next = NULL;
    return newbook;
}

// 在链表尾部插入图书信息
void InsertBook(Node **head, Book book)
{
    Node *newbook = CreateNode(book);
    if (*head == NULL)
        *head = newbook;
    else
    {
        Node *current = *head;
        while (current->next != NULL)
        {
            current = current->next;
        }
        current->next = newbook;
    }
}

// 根据书号删除图书信息
int DeleteBook(Node **head, char bookId[])
{
    Node *current = *head;
    Node *prev = NULL;
    while (current != NULL)
    {
        if (strcmp(current->book.bookId, bookId) == 0)
        {
            if (prev == NULL)
                *head = current->next; // 删除头节点
            else
                prev->next = current->next; // 删除非头节点
            free(current);
            printf("图书%s删除成功!\n", bookId);
            return 1;
        }
        prev = current;
        current = current->next;
    }
    return 0;
}

// 根据书号修改图书库存数量
int UpdateStock(Node *head, char bookId[], int newStock)
{
    Node *current = head;
    while (current != NULL)
    {
        if (strcmp(current->book.bookId, bookId) == 0)
        {
            current->book.stock = newStock;
            printf("图书%s的库存数量已修改为%d!\n",current->book.bookId,newStock);
            return 1;
        }
        current = current->next;
    }
    return 0;
}

// 根据书号查找图书信息
Node *FindBook(Node *head, char bookId[])
{
    printf("查找的图书信息:\n");
    Node *current = head;
    while (current != NULL)
    {
        if(strcmp(current->book.bookId, bookId) == 0)
        {
            printf("书号:%s,", current->book.bookId);
            printf("书名:%s,", current->book.title);
            printf("作者:%s,", current->book.author);
            printf("库存:%d\n", current->book.stock);
            return current;
        }
        current = current->next;
    }
    printf("未找到该图书信息。\n");
    return NULL;
}

// 遍历并输出所有图书信息
void TraverseList(Node *head)
{
    printf("图书列表:\n");
    Node *current = head;
    while (current != NULL)
    {
        printf("书号:%s,", current->book.bookId);
        printf("书名:%s,", current->book.title);
        printf("作者:%s,", current->book.author);
        printf("库存:%d\n", current->book.stock);
        current = current->next;
    }
}

// 主函数
int main()
{
    Node *head = NULL; // 链表头节点
    char bookId_find[4], bookId_update[4], bookId_delete[4];
    int num;
    scanf("%s", bookId_find);
    scanf("%s", bookId_update);
    scanf("%d", &num);
    scanf("%s", bookId_delete);

    // 添加图书信息
    Book book1 = {"001", "C程序设计", "谭浩强", 10};
    Book book2 = {"002", "数据结构", "严蔚敏", 5};
    Book book3 = {"003", "算法导论", "Thomas H. Cormen", 3};
    InsertBook(&head, book1);
    InsertBook(&head, book2);
    InsertBook(&head, book3);

    // 查找图书信息
    FindBook(head, bookId_find);

    // 修改图书库存数量
    UpdateStock(head, bookId_update, num);

    // 删除图书信息
    DeleteBook(&head, bookId_delete);

    // 遍历输出图书列表
    TraverseList(head);

    return 0;
}
