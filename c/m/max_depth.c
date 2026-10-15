/* Recursive maximum depth of an indexed binary tree. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 1023

static int64_t depth(const int64_t *nodes, size_t node_count, int64_t node)
{
    if (node == -1) return 0;
    if (node < 0 || (uint64_t)node >= node_count) return -1;
    const size_t index = (size_t)node;
    const int64_t left = nodes[3 * index + 1];
    const int64_t right = nodes[3 * index + 2];
    if (left < -1 || (left >= 0 && (uint64_t)left >= node_count) ||
        right < -1 || (right >= 0 && (uint64_t)right >= node_count)) return -1;
    const int64_t left_depth = depth(nodes, node_count, left);
    if (left_depth < 0) return -1;
    const int64_t right_depth = depth(nodes, node_count, right);
    if (right_depth < 0) return -1;
    return 1 + (left_depth > right_depth ? left_depth : right_depth);
}

int64_t max_depth(const int64_t *nodes, size_t node_count, int64_t root_index)
{
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return root_index == -1 ? 0 : -1;
    if (nodes == NULL || root_index < 0 || (uint64_t)root_index >= node_count) return -1;
    return depth(nodes, node_count, root_index);
}
