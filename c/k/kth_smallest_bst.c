/* Inorder DFS decrements k and stops as soon as the requested node is found. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 1023
#define MAX_VALUE 10000
#define INVALID_TREE_RESULT INT64_MIN

static int64_t kth_visit(const int64_t *nodes, size_t node_count, int64_t node,
                         int64_t *remaining)
{
    if (node == -1) return -1;
    if (node < 0 || (uint64_t)node >= node_count) return INVALID_TREE_RESULT;
    const size_t index = (size_t)node;
    const int64_t value = nodes[3 * index];
    const int64_t left = nodes[3 * index + 1], right = nodes[3 * index + 2];
    if (value < 0 || value > MAX_VALUE || left < -1 || right < -1 ||
        (left >= 0 && (uint64_t)left >= node_count) ||
        (right >= 0 && (uint64_t)right >= node_count)) return INVALID_TREE_RESULT;
    const int64_t left_result = kth_visit(nodes, node_count, left, remaining);
    if (left_result >= 0 || left_result == INVALID_TREE_RESULT) return left_result;
    --*remaining;
    if (*remaining == 0) return value;
    return kth_visit(nodes, node_count, right, remaining);
}

int64_t kth_smallest_bst(const int64_t *nodes, size_t node_count,
                         int64_t root_index, int64_t k)
{
    if (node_count == 0 || node_count > MAX_NODE_COUNT || nodes == NULL ||
        root_index < 0 || (uint64_t)root_index >= node_count || k < 1 ||
        (uint64_t)k > node_count) return -1;
    int64_t remaining = k;
    const int64_t result = kth_visit(nodes, node_count, root_index, &remaining);
    return result >= 0 ? result : -1;
}
