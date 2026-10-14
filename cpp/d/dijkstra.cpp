/* Portable flat-edge-list Dijkstra; see the benchmark guide for the contract. */
#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" std::int64_t dijkstra(const std::int64_t *edges, std::size_t vertices,
                                 std::size_t edge_count, std::size_t source,
                                 std::int64_t *distances, std::uint8_t *reachable) noexcept
{
    if (vertices == 0) return source == 0 && edge_count == 0 ? 0 : -3;
    if (source >= vertices) return -3;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto origin = edges[3 * edge];
        const auto destination = edges[3 * edge + 1];
        const auto weight = edges[3 * edge + 2];
        if (origin < 0 || destination < 0 || static_cast<std::uint64_t>(origin) >= vertices ||
            static_cast<std::uint64_t>(destination) >= vertices) return -3;
        if (weight < 0) return -4;
    }
    for (std::size_t vertex = 0; vertex < vertices; ++vertex) {
        distances[vertex] = 0;
        reachable[vertex] = 0;
    }
    reachable[source] = 1;
    for (std::size_t round = 0; round < vertices; ++round) {
        std::size_t selected = vertices;
        std::int64_t best = 0;
        for (std::size_t vertex = 0; vertex < vertices; ++vertex) {
            if (reachable[vertex] == 1 && (selected == vertices || distances[vertex] < best)) {
                selected = vertex;
                best = distances[vertex];
            }
        }
        if (selected == vertices) break;
        reachable[selected] = 2;
        for (std::size_t edge = 0; edge < edge_count; ++edge) {
            if (static_cast<std::size_t>(edges[3 * edge]) != selected) continue;
            const auto destination = static_cast<std::size_t>(edges[3 * edge + 1]);
            const auto weight = edges[3 * edge + 2];
            const auto base = distances[selected];
            if (base > std::numeric_limits<std::int64_t>::max() - weight) return -2;
            const auto candidate = base + weight;
            if (reachable[destination] != 2 &&
                (reachable[destination] == 0 || candidate < distances[destination])) {
                distances[destination] = candidate;
                reachable[destination] = 1;
            }
        }
    }
    for (std::size_t vertex = 0; vertex < vertices; ++vertex) {
        if (reachable[vertex] == 2) reachable[vertex] = 1;
    }
    return 0;
}
