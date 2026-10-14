/* Portable bounded all-pairs shortest paths; returns the requested source row. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 64;
}

extern "C" std::int64_t floyd_warshall(const std::int64_t *edges, std::size_t vertices,
                                        std::size_t edge_count, std::size_t source,
                                        std::int64_t *distances, std::uint8_t *reachable) noexcept {
    if (vertices == 0) return source == 0 && edge_count == 0 ? 0 : -3;
    if (vertices > max_vertices || source >= vertices) return -3;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto origin = edges[3 * edge], destination = edges[3 * edge + 1];
        if (origin < 0 || destination < 0 || static_cast<std::uint64_t>(origin) >= vertices ||
            static_cast<std::uint64_t>(destination) >= vertices) return -3;
    }

    std::int64_t all_distances[max_vertices * max_vertices] = {};
    std::uint8_t present[max_vertices * max_vertices] = {};
    for (std::size_t vertex = 0; vertex < vertices; ++vertex) present[vertex * vertices + vertex] = 1;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto origin = static_cast<std::size_t>(edges[3 * edge]);
        const auto destination = static_cast<std::size_t>(edges[3 * edge + 1]);
        const auto index = origin * vertices + destination;
        const auto weight = edges[3 * edge + 2];
        if (!present[index] || weight < all_distances[index]) {
            all_distances[index] = weight;
            present[index] = 1;
        }
    }
    for (std::size_t middle = 0; middle < vertices; ++middle) {
        for (std::size_t origin = 0; origin < vertices; ++origin) {
            const auto left_index = origin * vertices + middle;
            if (!present[left_index]) continue;
            for (std::size_t destination = 0; destination < vertices; ++destination) {
                const auto right_index = middle * vertices + destination;
                if (!present[right_index]) continue;
                const auto left = all_distances[left_index], right = all_distances[right_index];
                if ((right > 0 && left > INT64_MAX - right) ||
                    (right < 0 && left < INT64_MIN - right)) return -2;
                const auto candidate = left + right;
                const auto index = origin * vertices + destination;
                if (!present[index] || candidate < all_distances[index]) {
                    all_distances[index] = candidate;
                    present[index] = 1;
                }
            }
        }
    }
    for (std::size_t vertex = 0; vertex < vertices; ++vertex) {
        const auto index = source * vertices + vertex;
        if (present[index] && present[vertex * vertices + vertex] &&
            all_distances[vertex * vertices + vertex] < 0) return -1;
    }
    for (std::size_t vertex = 0; vertex < vertices; ++vertex) {
        const auto index = source * vertices + vertex;
        reachable[vertex] = present[index];
        distances[vertex] = present[index] ? all_distances[index] : 0;
    }
    return 0;
}
