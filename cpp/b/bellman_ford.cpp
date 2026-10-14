/* Independent portable Bellman-Ford; see the benchmark guide for references. */
#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" std::int64_t bellman_ford(const std::int64_t *edges, std::size_t vertices,
                                     std::size_t edge_count, std::size_t source,
                                     std::int64_t *distances, std::uint8_t *reachable) noexcept
{
    if (vertices == 0) return source == 0 && edge_count == 0 ? 0 : -3;
    if (source >= vertices) return -3;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto origin = edges[3 * edge];
        const auto destination = edges[3 * edge + 1];
        if (origin < 0 || destination < 0 || static_cast<std::uint64_t>(origin) >= vertices ||
            static_cast<std::uint64_t>(destination) >= vertices) return -3;
    }
    for (std::size_t vertex = 0; vertex < vertices; ++vertex) {
        distances[vertex] = 0;
        reachable[vertex] = 0;
    }
    reachable[source] = 1;
    for (std::size_t round = 0; round < vertices; ++round) {
        bool changed = false;
        for (std::size_t edge = 0; edge < edge_count; ++edge) {
            const auto origin = static_cast<std::size_t>(edges[3 * edge]);
            const auto destination = static_cast<std::size_t>(edges[3 * edge + 1]);
            const auto weight = edges[3 * edge + 2];
            if (!reachable[origin]) continue;
            const auto base = distances[origin];
            if ((weight > 0 && base > std::numeric_limits<std::int64_t>::max() - weight) ||
                (weight < 0 && base < std::numeric_limits<std::int64_t>::min() - weight)) return -2;
            const auto candidate = base + weight;
            if (!reachable[destination] || candidate < distances[destination]) {
                if (round == vertices - 1) return -1;
                distances[destination] = candidate;
                reachable[destination] = 1;
                changed = true;
            }
        }
        if (!changed) return 0;
    }
    return 0;
}
