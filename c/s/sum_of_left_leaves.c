/* Recursively sum leaf values whose incoming edge is a left-child edge. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 1023
#define ERROR_SENTINEL INT64_C(-2000000000)

static int64_t sum_left_leaves_visit(const int64_t *nodes, size_t node_count,
                                     int64_t node, int is_left)
{
    if (node == -1) return 0;
    if (node < 0 || (uint64_t)node >= node_count) return ERROR_SENTINEL;
    const size_t index = (size_t)node;
    const int64_t value = nodes[3 * index];
    const int64_t left = nodes[3 * index + 1];
    const int64_t right = nodes[3 * index + 2];
    if (value < -1000 || value > 1000 || left < -1 ||
        (left >= 0 && (uint64_t)left >= node_count) || right < -1 ||
        (right >= 0 && (uint64_t)right >= node_count)) return ERROR_SENTINEL;
    if (left == -1 && right == -1) return is_left ? value : 0;
    const int64_t left_sum = sum_left_leaves_visit(nodes, node_count, left, 1);
    if (left_sum == ERROR_SENTINEL) return ERROR_SENTINEL;
    const int64_t right_sum = sum_left_leaves_visit(nodes, node_count, right, 0);
    if (right_sum == ERROR_SENTINEL) return ERROR_SENTINEL;
    return left_sum + right_sum;
}

int64_t sum_of_left_leaves(const int64_t *nodes, size_t node_count, int64_t root_index)
{
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return root_index == -1 ? 0 : -1;
    if (nodes == NULL || root_index < 0 || (uint64_t)root_index >= node_count) return -1;
    const int64_t result = sum_left_leaves_visit(nodes, node_count, root_index, 0);
    return result == ERROR_SENTINEL ? -1 : result;
}
