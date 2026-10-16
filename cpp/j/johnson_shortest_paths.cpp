/* Bounded Johnson all-pairs shortest paths for the pinned R contract. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxVertices = 32;
constexpr std::size_t kMaxEdges = 256;
constexpr std::size_t kMaxInputLength = 770;
constexpr std::size_t kMaxQueue = kMaxEdges + 1;
constexpr std::int64_t kUnreachable = INT64_MAX;
constexpr std::int64_t kUnreachableSentinel = INT64_C(1) << 62;
constexpr std::uint64_t kFnvOffset = UINT64_C(14695981039346656037);
constexpr std::uint64_t kFnvPrime = UINT64_C(1099511628211);

std::uint64_t fnv_word(std::uint64_t hash, std::int64_t word) noexcept {
    const auto bits = static_cast<std::uint64_t>(word);
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (bits >> (8 * byte)) & UINT64_C(0xff);
        hash *= kFnvPrime;
    }
    return hash;
}
}

extern "C" std::int64_t johnson_shortest_paths(const std::int64_t *input,
                                                std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const auto vertex_value = input[0], edge_value = input[1];
    if (vertex_value < 1 || vertex_value > static_cast<std::int64_t>(kMaxVertices) ||
        edge_value < 0 || edge_value > static_cast<std::int64_t>(kMaxEdges)) return -1;
    const auto vertices = static_cast<std::size_t>(vertex_value);
    const auto edges = static_cast<std::size_t>(edge_value);
    if (length != 2 + 3 * edges) return -1;

    std::array<std::size_t, kMaxEdges> edge_from{};
    std::array<std::size_t, kMaxEdges> edge_to{};
    std::array<std::int64_t, kMaxEdges> edge_weight{};
    for (std::size_t edge = 0; edge < edges; ++edge) {
        const auto from = input[2 + 3 * edge];
        const auto to = input[3 + 3 * edge];
        const auto weight = input[4 + 3 * edge];
        if (from < 1 || from > vertex_value || to < 1 || to > vertex_value || weight < -32 || weight > 32) return -1;
        edge_from[edge] = static_cast<std::size_t>(from - 1);
        edge_to[edge] = static_cast<std::size_t>(to - 1);
        edge_weight[edge] = weight;
    }

    std::array<std::int64_t, kMaxVertices> potential{};
    for (std::size_t iteration = 1; iteration < vertices; ++iteration) {
        bool updated = false;
        for (std::size_t edge = 0; edge < edges; ++edge) {
            const auto from = edge_from[edge], to = edge_to[edge];
            const auto candidate = potential[from] + edge_weight[edge];
            if (candidate < potential[to]) {
                potential[to] = candidate;
                updated = true;
            }
        }
        if (!updated) break;
    }
    for (std::size_t edge = 0; edge < edges; ++edge)
        if (potential[edge_from[edge]] + edge_weight[edge] < potential[edge_to[edge]]) return -1;

    std::uint64_t result = kFnvOffset;
    for (std::size_t source = 0; source < vertices; ++source) {
        std::array<std::int64_t, kMaxVertices> distance;
        std::array<bool, kMaxVertices> visited{};
        distance.fill(kUnreachable);
        distance[source] = 0;

        std::array<std::size_t, kMaxQueue> queue_vertices{};
        std::array<std::int64_t, kMaxQueue> queue_distances{};
        std::size_t queue_length = 1;
        queue_vertices[0] = source;
        queue_distances[0] = 0;
        while (queue_length > 0) {
            std::size_t minimum = 0;
            for (std::size_t index = 1; index < queue_length; ++index)
                if (queue_distances[index] < queue_distances[minimum]) minimum = index;
            const auto current = queue_vertices[minimum];
            for (std::size_t index = minimum + 1; index < queue_length; ++index) {
                queue_vertices[index - 1] = queue_vertices[index];
                queue_distances[index - 1] = queue_distances[index];
            }
            --queue_length;
            if (visited[current]) continue;
            visited[current] = true;

            for (std::size_t edge = 0; edge < edges; ++edge) {
                if (edge_from[edge] != current) continue;
                const auto next = edge_to[edge];
                const auto reweighted = edge_weight[edge] + potential[current] - potential[next];
                const auto candidate = distance[current] + reweighted;
                if (!visited[next] && candidate < distance[next]) {
                    distance[next] = candidate;
                    queue_vertices[queue_length] = next;
                    queue_distances[queue_length] = candidate;
                    ++queue_length;
                }
            }
        }

        for (std::size_t destination = 0; destination < vertices; ++destination) {
            const auto output = distance[destination] == kUnreachable
                ? kUnreachableSentinel
                : distance[destination] - potential[source] + potential[destination];
            result = fnv_word(result, output);
        }
    }
    return static_cast<std::int64_t>(result & static_cast<std::uint64_t>(INT64_MAX));
}
