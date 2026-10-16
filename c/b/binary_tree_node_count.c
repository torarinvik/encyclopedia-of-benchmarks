/* Count nodes reachable from the root of a bounded indexed binary tree. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 900
#define INVALID_RESULT (-9000000000000000000LL)

static int64_t count_visit(const int64_t *nodes, size_t node_count, int64_t node, size_t depth)
{
    if (node < 0 || (uint64_t)node >= node_count || depth >= node_count) return INVALID_RESULT;
    const size_t index = (size_t)node;
    const int64_t left = nodes[3 * index + 1];
    const int64_t right = nodes[3 * index + 2];
    if (left < -1 ||
        (left >= 0 && (uint64_t)left >= node_count) || right < -1 ||
        (right >= 0 && (uint64_t)right >= node_count)) return INVALID_RESULT;
    const int64_t left_count = left == -1 ? 0 : count_visit(nodes, node_count, left, depth + 1);
    if (left_count == INVALID_RESULT) return INVALID_RESULT;
    const int64_t right_count = right == -1 ? 0 : count_visit(nodes, node_count, right, depth + 1);
    if (right_count == INVALID_RESULT) return INVALID_RESULT;
    return 1 + left_count + right_count;
}

int64_t binary_tree_node_count(const int64_t *nodes, size_t node_count, int64_t root_index)
{
    if (nodes == NULL || node_count == 0 || node_count > MAX_NODE_COUNT || root_index < 0 ||
        (uint64_t)root_index >= node_count) return INVALID_RESULT;
    return count_visit(nodes, node_count, root_index, 0);
}
