/* One-pass postorder height calculation, following the pinned Java method. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 1023

static int64_t balanced_height(const int64_t *nodes, size_t node_count,
                               int64_t node, int *balanced)
{
    if (node == -1 || !*balanced) return 0;
    if (node < 0 || (uint64_t)node >= node_count) return -1;
    const size_t index = (size_t)node;
    const int64_t left = nodes[3 * index + 1];
    const int64_t right = nodes[3 * index + 2];
    if (left < -1 || (left >= 0 && (uint64_t)left >= node_count) ||
        right < -1 || (right >= 0 && (uint64_t)right >= node_count)) return -1;
    const int64_t left_height = balanced_height(nodes, node_count, left, balanced);
    if (left_height < 0) return -1;
    const int64_t right_height = balanced_height(nodes, node_count, right, balanced);
    if (right_height < 0) return -1;
    const int64_t difference = left_height >= right_height
        ? left_height - right_height : right_height - left_height;
    if (difference > 1) *balanced = 0;
    return 1 + (left_height > right_height ? left_height : right_height);
}

int64_t check_if_binary_tree_balanced(const int64_t *nodes, size_t node_count,
                                     int64_t root_index)
{
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return root_index == -1 ? 1 : -1;
    if (nodes == NULL || root_index < 0 || (uint64_t)root_index >= node_count) return -1;
    int balanced = 1;
    const int64_t height = balanced_height(nodes, node_count, root_index, &balanced);
    return height < 0 ? -1 : balanced;
}
