#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 256
#define MAX_EDGE_COUNT 2047

static size_t find_root(size_t parent[MAX_NODE_COUNT + 1], size_t node)
{
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

int64_t connected_components_with_dsu(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || input[0] < 0 || input[0] > MAX_NODE_COUNT ||
        input[1] < 0 || input[1] > MAX_EDGE_COUNT)
        return -1;
    const size_t node_count = (size_t)input[0];
    const size_t edge_count = (size_t)input[1];
    if (length != 2 + 2 * edge_count) return -1;

    size_t parent[MAX_NODE_COUNT + 1], set_size[MAX_NODE_COUNT + 1];
    for (size_t node = 1; node <= node_count; ++node) {
        parent[node] = node;
        set_size[node] = 1;
    }
    size_t component_count = node_count;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t left_arg = input[2 + 2 * edge];
        const int64_t right_arg = input[3 + 2 * edge];
        if (left_arg < 1 || left_arg > (int64_t)node_count ||
            right_arg < 1 || right_arg > (int64_t)node_count)
            return -1;
        size_t left = find_root(parent, (size_t)left_arg);
        size_t right = find_root(parent, (size_t)right_arg);
        if (left == right) continue;
        if (set_size[left] < set_size[right]) {
            const size_t temporary = left;
            left = right;
            right = temporary;
        }
        parent[right] = left;
        set_size[left] += set_size[right];
        --component_count;
    }
    return (int64_t)component_count;
}
