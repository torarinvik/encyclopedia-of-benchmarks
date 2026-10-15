/* Trim a BST and serialize the retained indexed tree in preorder node-table order. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 100
#define MAX_VALUE 10000

static int valid_bst(const int64_t *nodes, size_t node_count, int64_t root_index)
{
    size_t parents[MAX_NODE_COUNT] = {0};
    for (size_t index = 0; index < node_count; ++index) {
        const int64_t value = nodes[3 * index];
        const int64_t left = nodes[3 * index + 1];
        const int64_t right = nodes[3 * index + 2];
        if (value < 1 || value > MAX_VALUE || left < -1 || right < -1 ||
            (left >= 0 && (uint64_t)left >= node_count) ||
            (right >= 0 && (uint64_t)right >= node_count)) return 0;
        if (left >= 0 && ++parents[(size_t)left] > 1) return 0;
        if (right >= 0 && ++parents[(size_t)right] > 1) return 0;
    }
    if (parents[(size_t)root_index] != 0) return 0;
    for (size_t index = 0; index < node_count; ++index)
        if (index != (size_t)root_index && parents[index] != 1) return 0;

    int64_t stack_node[MAX_NODE_COUNT], stack_low[MAX_NODE_COUNT], stack_high[MAX_NODE_COUNT];
    uint8_t seen[MAX_NODE_COUNT] = {0};
    size_t top = 1, visited = 0;
    stack_node[0] = root_index;
    stack_low[0] = 0;
    stack_high[0] = MAX_VALUE + 1;
    while (top > 0) {
        --top;
        const size_t index = (size_t)stack_node[top];
        const int64_t lower = stack_low[top], upper = stack_high[top];
        if (seen[index]) return 0;
        seen[index] = 1;
        ++visited;
        const int64_t value = nodes[3 * index];
        if (value <= lower || value >= upper) return 0;
        const int64_t left = nodes[3 * index + 1], right = nodes[3 * index + 2];
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
    return visited == node_count;
}

static int64_t trim_node(const int64_t *nodes, int64_t node, int64_t low, int64_t high,
                         int64_t *output, size_t *output_count)
{
    if (node == -1) return -1;
    const size_t index = (size_t)node;
    const int64_t value = nodes[3 * index];
    const int64_t left = nodes[3 * index + 1], right = nodes[3 * index + 2];
    if (value < low) return trim_node(nodes, right, low, high, output, output_count);
    if (value > high) return trim_node(nodes, left, low, high, output, output_count);

    const size_t trimmed_index = (*output_count)++;
    const size_t offset = 1 + 3 * trimmed_index;
    output[offset] = value;
    output[offset + 1] = -1;
    output[offset + 2] = -1;
    output[offset + 1] = trim_node(nodes, left, low, high, output, output_count);
    output[offset + 2] = trim_node(nodes, right, low, high, output, output_count);
    return (int64_t)trimmed_index;
}

int64_t trim_bst(const int64_t *nodes, size_t node_count, int64_t root_index,
                 int64_t low, int64_t high, int64_t *output, size_t output_capacity)
{
    if (node_count > MAX_NODE_COUNT || low < 1 || high > MAX_VALUE || low > high) return -1;
    if (node_count == 0) {
        if (root_index != -1) return -1;
        if (output == NULL || output_capacity < 1) return -2;
        output[0] = -1;
        return 1;
    }
    if (nodes == NULL || root_index < 0 || (uint64_t)root_index >= node_count ||
        !valid_bst(nodes, node_count, root_index)) return -1;
    if (output == NULL || output_capacity < 1 + 3 * node_count) return -2;

    size_t output_count = 0;
    output[0] = trim_node(nodes, root_index, low, high, output, &output_count);
    return (int64_t)(1 + 3 * output_count);
}
