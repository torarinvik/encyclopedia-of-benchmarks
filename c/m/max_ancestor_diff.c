/* Recursive path-minimum/path-maximum search for maximum ancestor difference. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 1023

static int64_t absolute_difference(int64_t left, int64_t right)
{
    return left >= right ? left - right : right - left;
}

static int64_t visit(const int64_t *nodes, size_t node_count, int64_t node,
                     int64_t path_min, int64_t path_max)
{
    if (node == -1) return 0;
    if (node < 0 || (uint64_t)node >= node_count) return -1;
    const size_t index = (size_t)node;
    const int64_t value = nodes[3 * index];
    if (value < -100000 || value > 100000) return -1;
    const int64_t left = nodes[3 * index + 1];
    const int64_t right = nodes[3 * index + 2];
    if (left < -1 || (left >= 0 && (uint64_t)left >= node_count) ||
        right < -1 || (right >= 0 && (uint64_t)right >= node_count)) return -1;
    int64_t best = absolute_difference(path_min, value);
    const int64_t high_difference = absolute_difference(path_max, value);
    if (high_difference > best) best = high_difference;
    const int64_t low = value < path_min ? value : path_min;
    const int64_t high = value > path_max ? value : path_max;
    const int64_t left_best = visit(nodes, node_count, left, low, high);
    if (left_best < 0) return -1;
    const int64_t right_best = visit(nodes, node_count, right, low, high);
    if (right_best < 0) return -1;
    if (left_best > best) best = left_best;
    if (right_best > best) best = right_best;
    return best;
}

int64_t max_ancestor_diff(const int64_t *nodes, size_t node_count, int64_t root_index)
{
    if (node_count == 0 || node_count > MAX_NODE_COUNT || nodes == NULL ||
        root_index < 0 || (uint64_t)root_index >= node_count) return -1;
    const int64_t root_value = nodes[3 * (size_t)root_index];
    if (root_value < -100000 || root_value > 100000) return -1;
    return visit(nodes, node_count, root_index, root_value, root_value);
}
