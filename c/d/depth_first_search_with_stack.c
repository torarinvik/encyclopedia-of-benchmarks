#include <stddef.h>
#include <stdint.h>

// Stack-based DFS that marks vertices when they are pushed, matching the source order.
int64_t depth_first_search_with_stack(const int64_t *values, size_t length,
                                      uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2 || length > 66 || (length - 2) % 2 != 0) return -2;
    if (values[0] < 0 || values[0] > 64) return -2;
    const size_t vertices = (size_t)values[0];
    const int64_t start_value = values[1];
    if (vertices == 0) return start_value == -1 && length == 2 ? 0 : -2;
    if (start_value < 0 || (uint64_t)start_value >= vertices) return -2;

    size_t adjacency[64 * 32] = {0};
    size_t degree[64] = {0};
    uint8_t state[64] = {0};
    const size_t edge_count = (length - 2) / 2;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t origin_value = values[2 + 2 * edge];
        const int64_t destination_value = values[3 + 2 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            (uint64_t)origin_value >= vertices || (uint64_t)destination_value >= vertices) return -2;
        const size_t origin = (size_t)origin_value;
        adjacency[origin * 32 + degree[origin]++] = (size_t)destination_value;
    }

    size_t stack[33];
    size_t stack_length = 1;
    size_t order[64];
    size_t count = 0;
    const size_t start = (size_t)start_value;
    state[start] = 1;
    stack[0] = start;
    while (stack_length != 0) {
        const size_t vertex = stack[--stack_length];
        if (state[vertex] != 1) continue;
        order[count++] = vertex;
        for (size_t edge = 0; edge < degree[vertex]; ++edge) {
            const size_t neighbor = adjacency[vertex * 32 + edge];
            stack[stack_length++] = neighbor;
            if (state[neighbor] != 2) state[neighbor] = 1;
        }
        state[vertex] = 2;
    }
    if (output_capacity < count || (count != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < count; ++index) output[index] = (uint8_t)order[index];
    return (int64_t)count;
}
