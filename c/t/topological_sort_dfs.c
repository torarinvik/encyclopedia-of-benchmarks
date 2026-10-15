/* Deterministic depth-first topological sort over a bounded directed graph. */
#include <stddef.h>
#include <stdint.h>

int64_t topological_sort_dfs(const int64_t *values, size_t length,
                             uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || length > 66 || (length - 1) % 2 != 0) return -2;
    if (values[0] < 0 || values[0] > 40) return -2;
    const size_t vertices = (size_t)values[0];
    const size_t edge_count = (length - 1) / 2;
    uint64_t adjacency[40] = {0};
    uint8_t state[40] = {0};
    size_t stack[40], next_neighbor[40], order[40];

    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t origin_value = values[1 + 2 * edge];
        const int64_t destination_value = values[2 + 2 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            (uint64_t)origin_value >= vertices || (uint64_t)destination_value >= vertices) return -2;
        adjacency[(size_t)origin_value] |= UINT64_C(1) << (size_t)destination_value;
    }

    size_t count = 0;
    for (size_t root = 0; root < vertices; ++root) {
        if (state[root] != 0) continue;
        size_t top = 0;
        stack[top] = root;
        next_neighbor[top] = 0;
        state[root] = 1;
        for (;;) {
            const size_t origin = stack[top];
            size_t destination = next_neighbor[top];
            while (destination < vertices &&
                   (adjacency[origin] & (UINT64_C(1) << destination)) == 0) ++destination;
            if (destination == vertices) {
                state[origin] = 2;
                order[count++] = origin;
                if (top == 0) break;
                --top;
                continue;
            }
            next_neighbor[top] = destination + 1;
            if (state[destination] == 1) return -1;
            if (state[destination] == 0) {
                ++top;
                stack[top] = destination;
                next_neighbor[top] = 0;
                state[destination] = 1;
            }
        }
    }

    if (output_capacity < vertices || (vertices != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < count; ++index)
        output[index] = (uint8_t)order[count - 1 - index];
    return (int64_t)count;
}
