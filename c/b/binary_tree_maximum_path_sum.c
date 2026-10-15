/* Recursive maximum-gain DFS with a best-path accumulator. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 1023
#define ERROR_SENTINEL INT64_C(-2000000000)

static int64_t maximum_gain(const int64_t *nodes, size_t node_count, int64_t node,
                           int64_t *best_path)
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
    const int64_t left_gain = maximum_gain(nodes, node_count, left, best_path);
    if (left_gain == ERROR_SENTINEL) return ERROR_SENTINEL;
    const int64_t right_gain = maximum_gain(nodes, node_count, right, best_path);
    if (right_gain == ERROR_SENTINEL) return ERROR_SENTINEL;
    const int64_t positive_left = left_gain > 0 ? left_gain : 0;
    const int64_t positive_right = right_gain > 0 ? right_gain : 0;
    const int64_t through_node = value + positive_left + positive_right;
    if (through_node > *best_path) *best_path = through_node;
    return value + (positive_left > positive_right ? positive_left : positive_right);
}

int64_t binary_tree_maximum_path_sum(const int64_t *nodes, size_t node_count,
                                    int64_t root_index)
{
    if (node_count == 0 || node_count > MAX_NODE_COUNT || nodes == NULL || root_index < 0 ||
        (uint64_t)root_index >= node_count) return -1;
    int64_t best_path = INT64_C(-2147483648);
    const int64_t gain = maximum_gain(nodes, node_count, root_index, &best_path);
    return gain == ERROR_SENTINEL ? -1 : best_path;
}
