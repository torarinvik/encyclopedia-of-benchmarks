/* Check strict BST bounds over a valid indexed binary tree. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 1023
#define VALUE_MIN (-2147483647LL - 1)
#define VALUE_MAX 2147483647LL

static int64_t validate_subtree(const int64_t *nodes, size_t node_count, int64_t node,
                                int has_lower, int64_t lower,
                                int has_upper, int64_t upper)
{
    if (node == -1) return 1;
    if (node < 0 || (uint64_t)node >= node_count) return -1;
    const size_t index = (size_t)node;
    const int64_t value = nodes[3 * index];
    const int64_t left = nodes[3 * index + 1];
    const int64_t right = nodes[3 * index + 2];
    if (value < VALUE_MIN || value > VALUE_MAX ||
        left < -1 || (left >= 0 && (uint64_t)left >= node_count) ||
        right < -1 || (right >= 0 && (uint64_t)right >= node_count)) return -1;
    if ((has_lower && value <= lower) || (has_upper && value >= upper)) return 0;
    const int64_t left_result =
        validate_subtree(nodes, node_count, left, has_lower, lower, 1, value);
    if (left_result <= 0) return left_result;
    return validate_subtree(nodes, node_count, right, 1, value, has_upper, upper);
}

int64_t validate_bst(const int64_t *nodes, size_t node_count, int64_t root_index)
{
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return root_index == -1 ? 1 : -1;
    if (nodes == NULL || root_index < 0 || (uint64_t)root_index >= node_count) return -1;
    return validate_subtree(nodes, node_count, root_index, 0, 0, 0, 0);
}
