/* Portable flat-edge-list Dijkstra; see the benchmark guide for the contract. */
#include <stddef.h>
#include <stdint.h>

int64_t dijkstra(const int64_t *edges, size_t vertices, size_t edge_count,
                 size_t source, int64_t *distances, uint8_t *reachable)
{
    if (vertices == 0) return source == 0 && edge_count == 0 ? 0 : -3;
    if (source >= vertices) return -3;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t origin = edges[3 * edge];
        const int64_t destination = edges[3 * edge + 1];
        const int64_t weight = edges[3 * edge + 2];
        if (origin < 0 || destination < 0 || (uint64_t)origin >= vertices ||
            (uint64_t)destination >= vertices) return -3;
        if (weight < 0) return -4;
    }
    for (size_t vertex = 0; vertex < vertices; ++vertex) {
        distances[vertex] = 0;
        reachable[vertex] = 0;
    }
    reachable[source] = 1;
    for (size_t round = 0; round < vertices; ++round) {
        size_t selected = vertices;
        int64_t best = 0;
        for (size_t vertex = 0; vertex < vertices; ++vertex) {
            if (reachable[vertex] == 1 && (selected == vertices || distances[vertex] < best)) {
                selected = vertex;
                best = distances[vertex];
            }
        }
        if (selected == vertices) break;
        reachable[selected] = 2;
        for (size_t edge = 0; edge < edge_count; ++edge) {
            if ((size_t)edges[3 * edge] != selected) continue;
            const size_t destination = (size_t)edges[3 * edge + 1];
            const int64_t weight = edges[3 * edge + 2];
            const int64_t base = distances[selected];
            if (base > INT64_MAX - weight) return -2;
            const int64_t candidate = base + weight;
            if (reachable[destination] != 2 &&
                (reachable[destination] == 0 || candidate < distances[destination])) {
                distances[destination] = candidate;
                reachable[destination] = 1;
            }
        }
    }
    for (size_t vertex = 0; vertex < vertices; ++vertex) {
        if (reachable[vertex] == 2) reachable[vertex] = 1;
    }
    return 0;
}
