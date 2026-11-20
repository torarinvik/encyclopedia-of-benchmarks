/* Lazy-heap Dijkstra; the graph contract is in the package README. */
#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_vertices = 64;
constexpr std::size_t max_edges = 256;
constexpr std::size_t max_heap = max_edges + 1;
constexpr std::size_t none = max_edges;

bool before(std::int64_t left_distance, std::size_t left_vertex,
            std::int64_t right_distance, std::size_t right_vertex) {
    return left_distance < right_distance ||
           (left_distance == right_distance && left_vertex < right_vertex);
}
} // namespace

extern "C" std::int64_t dijkstra_lazy_heap(const std::int64_t* edges,
                                             std::size_t vertices,
                                             std::size_t edge_count,
                                             std::size_t source,
                                             std::int64_t* distances,
                                             std::uint8_t* reachable) noexcept {
    if (vertices > max_vertices || edge_count > max_edges) return -3;
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

    std::array<std::size_t, max_vertices> head{};
    std::array<std::size_t, max_vertices> tail{};
    std::array<std::size_t, max_edges> next{};
    for (std::size_t vertex = 0; vertex < vertices; ++vertex) head[vertex] = tail[vertex] = none;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto origin = static_cast<std::size_t>(edges[3 * edge]);
        next[edge] = none;
        if (head[origin] == none) head[origin] = edge;
        else next[tail[origin]] = edge;
        tail[origin] = edge;
    }

    for (std::size_t vertex = 0; vertex < vertices; ++vertex) {
        distances[vertex] = 0;
        reachable[vertex] = 0;
    }
    std::array<std::int64_t, max_heap> heap_distance{};
    std::array<std::size_t, max_heap> heap_vertex{};
    std::size_t heap_count = 1;
    heap_distance[0] = 0;
    heap_vertex[0] = source;
    distances[source] = 0;
    reachable[source] = 1;

    while (heap_count > 0) {
        const auto current = heap_distance[0];
        const auto origin = heap_vertex[0];
        --heap_count;
        if (heap_count > 0) {
            const auto last_distance = heap_distance[heap_count];
            const auto last_vertex = heap_vertex[heap_count];
            std::size_t position = 0;
            while (2 * position + 1 < heap_count) {
                auto child = 2 * position + 1;
                if (child + 1 < heap_count && before(heap_distance[child + 1], heap_vertex[child + 1],
                                                     heap_distance[child], heap_vertex[child])) ++child;
                if (!before(heap_distance[child], heap_vertex[child], last_distance, last_vertex)) break;
                heap_distance[position] = heap_distance[child];
                heap_vertex[position] = heap_vertex[child];
                position = child;
            }
            heap_distance[position] = last_distance;
            heap_vertex[position] = last_vertex;
        }
        if (current != distances[origin] || reachable[origin] == 2) continue;
        reachable[origin] = 2;

        for (auto edge = head[origin]; edge != none; edge = next[edge]) {
            const auto destination = static_cast<std::size_t>(edges[3 * edge + 1]);
            const auto weight = edges[3 * edge + 2];
            if (current > std::numeric_limits<std::int64_t>::max() - weight) return -2;
            const auto candidate = current + weight;
            if (reachable[destination] != 2 &&
                (reachable[destination] == 0 || candidate < distances[destination])) {
                distances[destination] = candidate;
                reachable[destination] = 1;
                auto position = heap_count++;
                while (position > 0) {
                    const auto parent = (position - 1) / 2;
                    if (!before(candidate, destination, heap_distance[parent], heap_vertex[parent])) break;
                    heap_distance[position] = heap_distance[parent];
                    heap_vertex[position] = heap_vertex[parent];
                    position = parent;
                }
                heap_distance[position] = candidate;
                heap_vertex[position] = destination;
            }
        }
    }
    for (std::size_t vertex = 0; vertex < vertices; ++vertex)
        if (reachable[vertex] == 2) reachable[vertex] = 1;
    return 0;
}
