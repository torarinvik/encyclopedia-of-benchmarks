/* Recursive mirror comparison for an indexed binary tree. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 1023

static int64_t symmetric_tree_mirror(const int64_t *nodes, size_t node_count,
                                     int64_t left, int64_t right)
{
    if (left == -1 || right == -1) return left == right ? 1 : 0;
    if (left < 0 || right < 0 || (uint64_t)left >= node_count ||
        (uint64_t)right >= node_count) return -1;
    const size_t left_node = (size_t)left;
    const size_t right_node = (size_t)right;
    if (nodes[3 * left_node] != nodes[3 * right_node]) return 0;
    const int64_t left_left = nodes[3 * left_node + 1];
    const int64_t left_right = nodes[3 * left_node + 2];
    const int64_t right_left = nodes[3 * right_node + 1];
    const int64_t right_right = nodes[3 * right_node + 2];
    if (left_left < -1 || left_left >= (int64_t)node_count ||
        left_right < -1 || left_right >= (int64_t)node_count ||
        right_left < -1 || right_left >= (int64_t)node_count ||
        right_right < -1 || right_right >= (int64_t)node_count) return -1;
    const int64_t outer = symmetric_tree_mirror(nodes, node_count, left_left, right_right);
    if (outer != 1) return outer;
    return symmetric_tree_mirror(nodes, node_count, left_right, right_left);
}

int64_t symmetric_tree(const int64_t *nodes, size_t node_count, int64_t root_index)
{
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return root_index == -1 ? 1 : -1;
    if (nodes == NULL || root_index < 0 || (uint64_t)root_index >= node_count) return -1;
    const size_t root = (size_t)root_index;
    const int64_t left = nodes[3 * root + 1];
    const int64_t right = nodes[3 * root + 2];
    if (left < -1 || left >= (int64_t)node_count ||
        right < -1 || right >= (int64_t)node_count) return -1;
    return symmetric_tree_mirror(nodes, node_count, left, right);
}
