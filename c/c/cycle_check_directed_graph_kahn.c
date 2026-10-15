#include <stddef.h>
#include <stdint.h>

int64_t cycle_check_directed_graph_kahn(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > 65 || (length - 1) % 2 != 0) return -1;
    if (values[0] < 0 || values[0] > 64) return -1;
    const size_t vertices = (size_t)values[0];
    const size_t edge_count = (length - 1) / 2;
    if (edge_count > 32) return -1;
    uint64_t adjacency[64] = {0};
    size_t indegree[64] = {0};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t source_value = values[1 + 2 * edge];
        const int64_t destination_value = values[2 + 2 * edge];
        if (source_value < 0 || destination_value < 0 ||
            (uint64_t)source_value >= vertices || (uint64_t)destination_value >= vertices) return -1;
        const size_t source = (size_t)source_value;
        const size_t destination = (size_t)destination_value;
        const uint64_t mask = UINT64_C(1) << destination;
        if ((adjacency[source] & mask) == 0) {
            adjacency[source] |= mask;
            ++indegree[destination];
        }
    }
    size_t queue[64], head = 0, tail = 0;
    for (size_t vertex = 0; vertex < vertices; ++vertex)
        if (indegree[vertex] == 0) queue[tail++] = vertex;
    size_t removed = 0;
    while (head < tail) {
        const size_t source = queue[head++];
        ++removed;
        for (size_t destination = 0; destination < vertices; ++destination) {
            if ((adjacency[source] & (UINT64_C(1) << destination)) == 0) continue;
            if (--indegree[destination] == 0) queue[tail++] = destination;
        }
    }
    return removed == vertices ? 0 : 1;
}
