#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 400
#define INVALID_RESULT INT64_C(-9000000000000000000)

static int64_t subtree_sum(const int64_t *nodes, int64_t index) {
    if (index < 0) return 0;
    return nodes[3 * index] + subtree_sum(nodes, nodes[3 * index + 1]) + subtree_sum(nodes, nodes[3 * index + 2]);
}

static bool is_sum_tree_node(const int64_t *nodes, int64_t index) {
    const int64_t value = nodes[3 * index], left = nodes[3 * index + 1], right = nodes[3 * index + 2];
    if (left == -1 && right == -1) return true;
    const int64_t left_sum = subtree_sum(nodes, left), right_sum = subtree_sum(nodes, right);
    const bool left_ok = left == -1 || is_sum_tree_node(nodes, left);
    const bool right_ok = right == -1 || is_sum_tree_node(nodes, right);
    return value == left_sum + right_sum && left_ok && right_ok;
}

int64_t is_sum_tree(const int64_t *nodes, size_t count, int64_t root) {
    if (!nodes || count == 0 || count > MAX_NODES || root < 0 || (uint64_t)root >= count) return INVALID_RESULT;
    bool seen[MAX_NODES] = {false}; int64_t stack[MAX_NODES * 2]; size_t top = 0; stack[top++] = root;
    while (top) {
        const int64_t index = stack[--top];
        if (index < 0 || (uint64_t)index >= count || seen[index]) return INVALID_RESULT;
        seen[index] = true;
        const int64_t value = nodes[3 * index], left = nodes[3 * index + 1], right = nodes[3 * index + 2];
        if (value < -1000000000 || value > 1000000000 || left < -1 || right < -1 ||
            (left >= 0 && (uint64_t)left >= count) || (right >= 0 && (uint64_t)right >= count)) return INVALID_RESULT;
        if (left >= 0) stack[top++] = left;
        if (right >= 0) stack[top++] = right;
    }
    return is_sum_tree_node(nodes, root) ? 1 : 0;
}
