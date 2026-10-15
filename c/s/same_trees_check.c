/* Breadth-first structural and value comparison of two indexed binary trees. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 1023

typedef struct {
    size_t count;
    int64_t root;
    const int64_t *rows;
} tree_view;

static int parse_tree(const int64_t *input, size_t length, size_t *offset, tree_view *tree)
{
    if (*offset > length || length - *offset < 2) return 0;
    const int64_t count_value = input[*offset];
    const int64_t root = input[*offset + 1];
    if (count_value < 0 || count_value > MAX_NODE_COUNT) return 0;
    const size_t count = (size_t)count_value;
    const size_t row_start = *offset + 2;
    if (count > (length - row_start) / 3) return 0;
    tree->count = count;
    tree->root = root;
    tree->rows = input + row_start;
    *offset = row_start + 3 * count;
    return 1;
}

static int valid_tree(const tree_view *tree)
{
    if (tree->count == 0) return tree->root == -1;
    if (tree->root < 0 || (uint64_t)tree->root >= tree->count) return 0;
    size_t parents[MAX_NODE_COUNT] = {0};
    for (size_t index = 0; index < tree->count; ++index) {
        const int64_t value = tree->rows[3 * index];
        const int64_t left = tree->rows[3 * index + 1];
        const int64_t right = tree->rows[3 * index + 2];
        if (value < INT32_MIN || value > INT32_MAX || left < -1 || right < -1 ||
            (left >= 0 && (uint64_t)left >= tree->count) ||
            (right >= 0 && (uint64_t)right >= tree->count)) return 0;
        if (left >= 0 && ++parents[(size_t)left] > 1) return 0;
        if (right >= 0 && ++parents[(size_t)right] > 1) return 0;
    }
    for (size_t index = 0; index < tree->count; ++index) {
        const size_t expected = index == (size_t)tree->root ? 0 : 1;
        if (parents[index] != expected) return 0;
    }
    size_t queue[MAX_NODE_COUNT];
    uint8_t seen[MAX_NODE_COUNT] = {0};
    size_t head = 0, tail = 0;
    queue[tail++] = (size_t)tree->root;
    while (head < tail) {
        const size_t index = queue[head++];
        if (seen[index]) return 0;
        seen[index] = 1;
        const int64_t left = tree->rows[3 * index + 1];
        const int64_t right = tree->rows[3 * index + 2];
        if (left >= 0) queue[tail++] = (size_t)left;
        if (right >= 0) queue[tail++] = (size_t)right;
    }
    return tail == tree->count;
}

static int trees_equal(const tree_view *first, const tree_view *second)
{
    if (first->root == -1 || second->root == -1) return first->root == second->root;
    int64_t queue1[MAX_NODE_COUNT], queue2[MAX_NODE_COUNT];
    size_t head = 0, tail = 0;
    queue1[tail] = first->root;
    queue2[tail++] = second->root;
    while (head < tail) {
        const size_t index1 = (size_t)queue1[head];
        const size_t index2 = (size_t)queue2[head++];
        const int64_t *a = first->rows + 3 * index1;
        const int64_t *b = second->rows + 3 * index2;
        if (a[0] != b[0] || (a[1] == -1) != (b[1] == -1) ||
            (a[2] == -1) != (b[2] == -1)) return 0;
        if (a[1] >= 0) { queue1[tail] = a[1]; queue2[tail++] = b[1]; }
        if (a[2] >= 0) { queue1[tail] = a[2]; queue2[tail++] = b[2]; }
    }
    return 1;
}

int64_t same_trees_check(const int64_t *input, size_t length)
{
    if (input == NULL || length < 4) return -1;
    size_t offset = 0;
    tree_view first, second;
    if (!parse_tree(input, length, &offset, &first) ||
        !parse_tree(input, length, &offset, &second) || offset != length ||
        first.count + second.count > MAX_NODE_COUNT ||
        !valid_tree(&first) || !valid_tree(&second)) return -1;
    return trees_equal(&first, &second);
}
