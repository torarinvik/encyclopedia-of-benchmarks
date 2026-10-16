#include <stddef.h>
#include <stdint.h>

// Return vertices with no outgoing neighbors, in ascending vertex order.
int64_t find_isolated_nodes(const int64_t *values, size_t length,
                            uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || length > 65 || (length - 1) % 2 != 0) return -2;
    if (values[0] < 0 || values[0] > 64) return -2;
    const size_t vertices = (size_t)values[0];
    uint64_t adjacency[64] = {0};
    const size_t edge_count = (length - 1) / 2;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t origin_value = values[1 + 2 * edge];
        const int64_t destination_value = values[2 + 2 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            (uint64_t)origin_value >= vertices || (uint64_t)destination_value >= vertices) return -2;
        adjacency[(size_t)origin_value] |= UINT64_C(1) << (size_t)destination_value;
    }
    uint8_t isolated[64];
    size_t count = 0;
    for (size_t vertex = 0; vertex < vertices; ++vertex)
        if (adjacency[vertex] == 0) isolated[count++] = (uint8_t)vertex;
    if (output_capacity < count || (count != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < count; ++index) output[index] = isolated[index];
    return (int64_t)count;
}
