/* Run unique-key AVL insert/search/delete operations and emit normalized output. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 128
#define MAX_OPS 128
typedef struct { int64_t key; int left, right, height; } AvlNode;

static int height(const AvlNode *nodes, int index) { return index < 0 ? 0 : nodes[index].height; }
static void update_height(AvlNode *nodes, int index) {
    int left = height(nodes, nodes[index].left), right = height(nodes, nodes[index].right);
    nodes[index].height = 1 + (left > right ? left : right);
}
static int rotate_right(AvlNode *nodes, int root) {
    int pivot = nodes[root].left, middle = nodes[pivot].right;
    nodes[pivot].right = root; nodes[root].left = middle;
    update_height(nodes, root); update_height(nodes, pivot); return pivot;
}
static int rotate_left(AvlNode *nodes, int root) {
    int pivot = nodes[root].right, middle = nodes[pivot].left;
    nodes[pivot].left = root; nodes[root].right = middle;
    update_height(nodes, root); update_height(nodes, pivot); return pivot;
}
static int rebalance(AvlNode *nodes, int root) {
    if (root < 0) return root;
    update_height(nodes, root);
    int balance = height(nodes, nodes[root].left) - height(nodes, nodes[root].right);
    if (balance > 1) {
        int left = nodes[root].left;
        if (height(nodes, nodes[left].right) > height(nodes, nodes[left].left))
            nodes[root].left = rotate_left(nodes, left);
        return rotate_right(nodes, root);
    }
    if (balance < -1) {
        int right = nodes[root].right;
        if (height(nodes, nodes[right].left) > height(nodes, nodes[right].right))
            nodes[root].right = rotate_right(nodes, right);
        return rotate_left(nodes, root);
    }
    return root;
}
static int insert_node(AvlNode *nodes, int root, int64_t key, int *next) {
    if (root < 0) { int index = (*next)++; nodes[index] = (AvlNode){key, -1, -1, 1}; return index; }
    if (key < nodes[root].key) nodes[root].left = insert_node(nodes, nodes[root].left, key, next);
    else nodes[root].right = insert_node(nodes, nodes[root].right, key, next);
    return rebalance(nodes, root);
}
static int find_node(const AvlNode *nodes, int root, int64_t key) {
    while (root >= 0) {
        if (nodes[root].key == key) return root;
        root = key < nodes[root].key ? nodes[root].left : nodes[root].right;
    }
    return -1;
}
static int maximum_node(const AvlNode *nodes, int root) {
    while (nodes[root].right >= 0) root = nodes[root].right;
    return root;
}
static int delete_node(AvlNode *nodes, int root, int64_t key) {
    if (key < nodes[root].key) nodes[root].left = delete_node(nodes, nodes[root].left, key);
    else if (key > nodes[root].key) nodes[root].right = delete_node(nodes, nodes[root].right, key);
    else {
        if (nodes[root].left < 0) return nodes[root].right;
        if (nodes[root].right < 0) return nodes[root].left;
        int predecessor = maximum_node(nodes, nodes[root].left);
        nodes[root].key = nodes[predecessor].key;
        nodes[root].left = delete_node(nodes, nodes[root].left, nodes[predecessor].key);
    }
    return rebalance(nodes, root);
}
static void put_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

extern "C" int64_t avltree_unique_key_ops(const int64_t *input, size_t length,
                               uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1) return -1;
    int64_t operation_count = input[0];
    if (operation_count < 0 || operation_count > MAX_OPS || length != (size_t)(1 + 2 * operation_count)) return -1;
    int64_t active[MAX_NODES]; size_t active_count = 0, search_count = 0;
    for (size_t index = 0; index < (size_t)operation_count; ++index) {
        int64_t operation = input[1 + 2 * index], key = input[2 + 2 * index];
        if (operation < 0 || operation > 2 || key < -1000000 || key > 1000000) return -1;
        size_t found = active_count;
        for (size_t i = 0; i < active_count; ++i) if (active[i] == key) { found = i; break; }
        if (operation == 0) {
            if (found != active_count || active_count >= MAX_NODES) return -1;
            active[active_count++] = key;
        } else if (operation == 1) {
            ++search_count;
        } else {
            if (found == active_count) return -1;
            for (size_t i = found + 1; i < active_count; ++i) active[i - 1] = active[i];
            --active_count;
        }
    }

    AvlNode nodes[MAX_NODES]; int root = -1, next = 0;
    uint8_t search_results[MAX_OPS]; size_t result_count = 0;
    for (size_t index = 0; index < (size_t)operation_count; ++index) {
        int64_t operation = input[1 + 2 * index], key = input[2 + 2 * index];
        if (operation == 0) root = insert_node(nodes, root, key, &next);
        else if (operation == 1) search_results[result_count++] = (uint8_t)(find_node(nodes, root, key) >= 0);
        else root = delete_node(nodes, root, key);
    }
    size_t bytes = (2 + active_count + search_count) * 8;
    if (output == NULL || capacity < bytes) return -2;
    put_i64(output, 0, (int64_t)active_count);
    int stack[MAX_NODES], top = 0, current = root; size_t out = 1;
    while (current >= 0 || top > 0) {
        while (current >= 0) { stack[top++] = current; current = nodes[current].left; }
        current = stack[--top]; put_i64(output, out++ * 8, nodes[current].key); current = nodes[current].right;
    }
    put_i64(output, out++ * 8, (int64_t)search_count);
    for (size_t i = 0; i < search_count; ++i) put_i64(output, out++ * 8, search_results[i]);
    return (int64_t)bytes;
}
