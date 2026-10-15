#include <stddef.h>
#include <stdint.h>

#define MAX_OPS 128
#define MAX_NODES (MAX_OPS + 1)
#define KEY_MIN (-1000000)
#define KEY_MAX 1000000

typedef struct { int32_t key; int left, right; int64_t priority; } Node;

static int64_t priority_for(int32_t key) {
    return (((int64_t)key + 1000000) * 1103515245 + 12345) % 2147483648LL;
}
static int contains(const Node *nodes, int root, int32_t key) {
    if (root == 0) return 0;
    if (key == nodes[root].key) return 1;
    return contains(nodes, key < nodes[root].key ? nodes[root].left : nodes[root].right, key);
}
static int rotate_right(Node *nodes, int root) {
    int pivot = nodes[root].left;
    nodes[root].left = nodes[pivot].right;
    nodes[pivot].right = root;
    return pivot;
}
static int rotate_left(Node *nodes, int root) {
    int pivot = nodes[root].right;
    nodes[root].right = nodes[pivot].left;
    nodes[pivot].left = root;
    return pivot;
}
static int insert_node(Node *nodes, int *next, int root, int32_t key) {
    if (root == 0) {
        int id = (*next)++;
        nodes[id] = (Node){key, 0, 0, priority_for(key)};
        return id;
    }
    if (key == nodes[root].key) return root;
    if (key < nodes[root].key) {
        nodes[root].left = insert_node(nodes, next, nodes[root].left, key);
        if (nodes[nodes[root].left].priority > nodes[root].priority) root = rotate_right(nodes, root);
    } else {
        nodes[root].right = insert_node(nodes, next, nodes[root].right, key);
        if (nodes[nodes[root].right].priority > nodes[root].priority) root = rotate_left(nodes, root);
    }
    return root;
}
static int merge(Node *nodes, int left, int right) {
    if (left == 0) return right;
    if (right == 0) return left;
    if (nodes[left].priority > nodes[right].priority) {
        nodes[left].right = merge(nodes, nodes[left].right, right);
        return left;
    }
    nodes[right].left = merge(nodes, left, nodes[right].left);
    return right;
}
static int erase_node(Node *nodes, int root, int32_t key) {
    if (key < nodes[root].key) nodes[root].left = erase_node(nodes, nodes[root].left, key);
    else if (key > nodes[root].key) nodes[root].right = erase_node(nodes, nodes[root].right, key);
    else return merge(nodes, nodes[root].left, nodes[root].right);
    return root;
}
static void put_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t treap_unique_key_set(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || input[0] < 0 || input[0] > MAX_OPS || length != 1 + 2 * (size_t)input[0]) return -1;
    size_t operations = (size_t)input[0];
    for (size_t i = 0; i < operations; ++i) {
        int64_t op = input[1 + 2 * i], key = input[2 + 2 * i];
        if ((op != 0 && op != 1) || key < KEY_MIN || key > KEY_MAX) return -1;
    }
    Node nodes[MAX_NODES] = {{0}};
    int next = 1, root = 0;
    for (size_t i = 0; i < operations; ++i) {
        int op = (int)input[1 + 2 * i];
        int32_t key = (int32_t)input[2 + 2 * i];
        int present = contains(nodes, root, key);
        if ((op == 0 && present) || (op == 1 && !present)) return -1;
        root = op == 0 ? insert_node(nodes, &next, root, key) : erase_node(nodes, root, key);
    }
    int stack[MAX_OPS];
    int top = 0, current = root;
    int64_t sorted[MAX_OPS];
    size_t count = 0;
    while (current != 0 || top > 0) {
        while (current != 0) { stack[top++] = current; current = nodes[current].left; }
        current = stack[--top];
        sorted[count++] = nodes[current].key;
        current = nodes[current].right;
    }
    size_t required = count * 8;
    if (output == NULL || capacity < required) return -2;
    for (size_t i = 0; i < count; ++i) put_i64(output, 8 * i, sorted[i]);
    return (int64_t)count;
}
