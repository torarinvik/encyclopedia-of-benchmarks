#include <stddef.h>
#include <stdint.h>

// Traverse the directed graph from start using an explicit fixed-capacity graph.
int64_t depth_first_search(const int64_t *values, size_t length,
                   uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2 || length > 66 || (length - 2) % 2 != 0) return -2;
    if (values[0] < 0 || values[0] > 64) return -2;
    const size_t vertices = (size_t)values[0];
    const int64_t start_value = values[1];
    if (vertices == 0) return start_value == -1 && length == 2 ? 0 : -2;
    if (start_value < 0 || (uint64_t)start_value >= vertices) return -2;
    uint64_t adjacency[64] = {0};
    uint8_t visited[64] = {0};
    const size_t edge_count = (length - 2) / 2;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t origin_value = values[2 + 2 * edge];
        const int64_t destination_value = values[3 + 2 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            (uint64_t)origin_value >= vertices || (uint64_t)destination_value >= vertices) return -2;
        adjacency[(size_t)origin_value] |= UINT64_C(1) << (size_t)destination_value;
    }
    const size_t start = (size_t)start_value;
    size_t order[64];
    size_t count = 0;
    visited[start] = 1;
    size_t stack_vertex[64], stack_next[64], depth = 1;
    stack_vertex[0] = start;
    stack_next[0] = 0;
    order[count++] = start;
    while (depth != 0) {
        const size_t frame = depth - 1;
        const size_t origin = stack_vertex[frame];
        if (stack_next[frame] == vertices) {
            --depth;
            continue;
        }
        const size_t destination = stack_next[frame]++;
        if ((adjacency[origin] & (UINT64_C(1) << destination)) != 0 && !visited[destination]) {
            visited[destination] = 1;
            order[count++] = destination;
            stack_vertex[depth] = destination;
            stack_next[depth] = 0;
            ++depth;
        }
    }
    if (output_capacity < count || (count != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < count; ++index) output[index] = (uint8_t)order[index];
    return (int64_t)count;
}
