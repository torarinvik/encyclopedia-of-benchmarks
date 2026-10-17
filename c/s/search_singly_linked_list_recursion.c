#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 64
#define I32_MIN INT64_C(-2147483648)
#define I32_MAX INT64_C(2147483647)

typedef struct Node { int32_t value; struct Node *next; } Node;

static int search_recursion(const Node *node, int32_t key) {
    return node != NULL && (node->value == key || search_recursion(node->next, key));
}

int64_t search_singly_linked_list_recursion(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_NODES + 2) return -1;
    int64_t count_value = input[0], key_value = input[1];
    if (count_value < 0 || count_value > MAX_NODES || length != (size_t)count_value + 2 ||
        key_value < I32_MIN || key_value > I32_MAX) return -1;
    size_t count = (size_t)count_value;
    Node nodes[MAX_NODES];
    for (size_t i = 0; i < count; ++i) {
        int64_t value = input[i + 2];
        if (value < I32_MIN || value > I32_MAX) return -1;
        nodes[i].value = (int32_t)value;
        nodes[i].next = i + 1 < count ? &nodes[i + 1] : NULL;
    }
    return search_recursion(count == 0 ? NULL : nodes, (int32_t)key_value) ? 1 : 0;
}
