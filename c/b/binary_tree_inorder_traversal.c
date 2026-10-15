/* Recursive inorder traversal that writes into caller-owned storage. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 100
#define MIN_VALUE (-100)
#define MAX_VALUE 100

static int visit_inorder(const int64_t *nodes, size_t node_count, int64_t node,
                         int64_t *output, size_t capacity, size_t *used)
{
    if (node == -1) return 1;
    if (node < 0 || (uint64_t)node >= node_count) return 0;
    const size_t index = (size_t)node;
    const int64_t value = nodes[3 * index];
    const int64_t left = nodes[3 * index + 1], right = nodes[3 * index + 2];
    if (value < MIN_VALUE || value > MAX_VALUE || left < -1 || right < -1 ||
        (left >= 0 && (uint64_t)left >= node_count) ||
        (right >= 0 && (uint64_t)right >= node_count)) return 0;
    if (!visit_inorder(nodes, node_count, left, output, capacity, used)) return 0;
    if (*used >= capacity) return 0;
    output[(*used)++] = value;
    return visit_inorder(nodes, node_count, right, output, capacity, used);
}

int64_t binary_tree_inorder_traversal(const int64_t *nodes, size_t node_count,
                                      int64_t root_index, int64_t *output,
                                      size_t output_capacity)
{
    if (node_count > MAX_NODE_COUNT || output_capacity < node_count) return -1;
    if (node_count == 0) return root_index == -1 ? 0 : -1;
    if (nodes == NULL || output == NULL || root_index < 0 ||
        (uint64_t)root_index >= node_count) return -1;
    size_t used = 0;
    if (!visit_inorder(nodes, node_count, root_index, output, output_capacity, &used) ||
        used != node_count) return -1;
    return (int64_t)used;
}
