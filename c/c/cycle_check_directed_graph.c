#include <stddef.h>
#include <stdint.h>

static int has_cycle_dfs(size_t origin, size_t vertices,
                         const uint64_t adjacency[64], uint8_t state[64],
                         size_t stack[64], size_t next_neighbor[64])
{
    size_t top = 0;
    stack[0] = origin;
    next_neighbor[0] = 0;
    state[origin] = 1;
    for (;;) {
        const size_t node = stack[top];
        size_t destination = next_neighbor[top];
        while (destination < vertices &&
               (adjacency[node] & (UINT64_C(1) << destination)) == 0) ++destination;
        if (destination == vertices) {
            state[node] = 2;
            if (top == 0) return 0;
            --top;
            continue;
        }
        next_neighbor[top] = destination + 1;
        if (state[destination] == 1) return 1;
        if (state[destination] == 0) {
            ++top;
            stack[top] = destination;
            next_neighbor[top] = 0;
            state[destination] = 1;
        }
    }
}

int64_t cycle_check_directed_graph(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > 65 || (length - 1) % 2 != 0) return -1;
    if (values[0] < 0 || values[0] > 64) return -1;
    const size_t vertices = (size_t)values[0];
    const size_t edge_count = (length - 1) / 2;
    if (edge_count > 32) return -1;
    uint64_t adjacency[64] = {0};
    uint8_t state[64] = {0};
    size_t stack[64], next_neighbor[64];
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t source_value = values[1 + 2 * edge];
        const int64_t destination_value = values[2 + 2 * edge];
        if (source_value < 0 || destination_value < 0 ||
            (uint64_t)source_value >= vertices || (uint64_t)destination_value >= vertices) return -1;
        adjacency[(size_t)source_value] |= UINT64_C(1) << (size_t)destination_value;
    }
    for (size_t root = 0; root < vertices; ++root)
        if (state[root] == 0 && has_cycle_dfs(root, vertices, adjacency, state, stack, next_neighbor)) return 1;
    return 0;
}
