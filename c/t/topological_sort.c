/* Kahn topological sort over a bounded directed graph encoded as edge pairs. */
#include <stddef.h>
#include <stdint.h>

int64_t topological_sort(const int64_t *values, size_t length,
                         uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || length > 66 || (length - 1) % 2 != 0) return -2;
    if (values[0] < 0 || values[0] > 64) return -2;
    const size_t vertices = (size_t)values[0];
    const size_t edge_count = (length - 1) / 2;
    uint64_t adjacency[64] = {0};
    size_t indegree[64] = {0};
    size_t queue[64], order[64];

    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t origin_value = values[1 + 2 * edge];
        const int64_t destination_value = values[2 + 2 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            (uint64_t)origin_value >= vertices || (uint64_t)destination_value >= vertices) return -2;
        const size_t origin = (size_t)origin_value, destination = (size_t)destination_value;
        const uint64_t mask = UINT64_C(1) << destination;
        if ((adjacency[origin] & mask) == 0) {
            adjacency[origin] |= mask;
            ++indegree[destination];
        }
    }
    size_t head = 0, tail = 0;
    for (size_t vertex = 0; vertex < vertices; ++vertex)
        if (indegree[vertex] == 0) queue[tail++] = vertex;
    size_t count = 0;
    while (head < tail) {
        const size_t origin = queue[head++];
        order[count++] = origin;
        for (size_t destination = 0; destination < vertices; ++destination) {
            if ((adjacency[origin] & (UINT64_C(1) << destination)) != 0) {
                if (--indegree[destination] == 0) queue[tail++] = destination;
            }
        }
    }
    if (count != vertices) return -1;
    if (output_capacity < vertices || (vertices != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < count; ++index) output[index] = (uint8_t)order[index];
    return (int64_t)count;
}
