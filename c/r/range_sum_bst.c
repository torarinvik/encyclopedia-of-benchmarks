/* Preserve the source's full tree traversal while validating the BST input. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 1023
#define MAX_VALUE 100000

int64_t range_sum_bst(const int64_t *nodes, size_t node_count,
                      int64_t root_index, int64_t low, int64_t high)
{
    if (node_count > MAX_NODE_COUNT || low < 1 || high > MAX_VALUE || low > high) return -1;
    if (node_count == 0) return root_index == -1 ? 0 : -1;
    if (nodes == NULL || root_index < 0 || (uint64_t)root_index >= node_count) return -1;

    int64_t parents[MAX_NODE_COUNT] = {0};
    for (size_t index = 0; index < node_count; ++index) {
        const int64_t value = nodes[3 * index];
        const int64_t left = nodes[3 * index + 1];
        const int64_t right = nodes[3 * index + 2];
        if (value < 1 || value > MAX_VALUE || left < -1 || right < -1 ||
            (left >= 0 && (uint64_t)left >= node_count) ||
            (right >= 0 && (uint64_t)right >= node_count)) return -1;
        if (left >= 0 && ++parents[(size_t)left] > 1) return -1;
        if (right >= 0 && ++parents[(size_t)right] > 1) return -1;
    }
    if (parents[(size_t)root_index] != 0) return -1;
    for (size_t index = 0; index < node_count; ++index)
        if (index != (size_t)root_index && parents[index] != 1) return -1;

    int64_t stack_node[MAX_NODE_COUNT], stack_low[MAX_NODE_COUNT], stack_high[MAX_NODE_COUNT];
    int64_t seen[MAX_NODE_COUNT] = {0};
    size_t top = 1, visited = 0;
    stack_node[0] = root_index;
    stack_low[0] = 0;
    stack_high[0] = MAX_VALUE + 1;
    int64_t total = 0;
    while (top != 0) {
        --top;
        const size_t index = (size_t)stack_node[top];
        const int64_t lower = stack_low[top], upper = stack_high[top];
        if (seen[index] != 0) return -1;
        seen[index] = 1;
        ++visited;
        const int64_t value = nodes[3 * index];
        const int64_t left = nodes[3 * index + 1], right = nodes[3 * index + 2];
        if (value <= lower || value >= upper) return -1;
        if (low <= value && value <= high) total += value;
        if (right >= 0) {
            stack_node[top] = right;
            stack_low[top] = value;
            stack_high[top++] = upper;
        }
        if (left >= 0) {
            stack_node[top] = left;
            stack_low[top] = lower;
            stack_high[top++] = value;
        }
    }
    return visited == node_count ? total : -1;
}
