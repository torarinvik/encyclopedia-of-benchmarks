/* Independent portable Bellman-Ford; see the benchmark guide for references. */
#include <stddef.h>
#include <stdint.h>

int64_t bellman_ford(const int64_t *edges, size_t vertices, size_t edge_count,
                    size_t source, int64_t *distances, uint8_t *reachable)
{
    if (vertices == 0) return source == 0 && edge_count == 0 ? 0 : -3;
    if (source >= vertices) return -3;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t origin = edges[3 * edge];
        const int64_t destination = edges[3 * edge + 1];
        if (origin < 0 || destination < 0 || (uint64_t)origin >= vertices ||
            (uint64_t)destination >= vertices) return -3;
    }
    for (size_t vertex = 0; vertex < vertices; ++vertex) {
        distances[vertex] = 0;
        reachable[vertex] = 0;
    }
    reachable[source] = 1;
    for (size_t round = 0; round < vertices; ++round) {
        int changed = 0;
        for (size_t edge = 0; edge < edge_count; ++edge) {
            const size_t origin = (size_t)edges[3 * edge];
            const size_t destination = (size_t)edges[3 * edge + 1];
            const int64_t weight = edges[3 * edge + 2];
            if (!reachable[origin]) continue;
            const int64_t base = distances[origin];
            if ((weight > 0 && base > INT64_MAX - weight) ||
                (weight < 0 && base < INT64_MIN - weight)) return -2;
            const int64_t candidate = base + weight;
            if (!reachable[destination] || candidate < distances[destination]) {
                if (round == vertices - 1) return -1;
                distances[destination] = candidate;
                reachable[destination] = 1;
                changed = 1;
            }
        }
        if (!changed) return 0;
    }
    return 0;
}
