/* Bounded Johnson all-pairs distances for the pinned Java matrix contract. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxVertices = 16;
constexpr std::size_t kMaxInputLength = 1 + kMaxVertices * kMaxVertices;
constexpr std::int64_t kMaxWeight = 32;
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

extern "C" std::int64_t johnsons_algorithm(const std::int64_t *input,
                                             std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > kMaxInputLength) return -1;
    const auto vertex_value = input[0];
    if (vertex_value < 1 || vertex_value > static_cast<std::int64_t>(kMaxVertices)) return -1;
    const auto vertices = static_cast<std::size_t>(vertex_value);
    if (length != 1 + vertices * vertices) return -1;

    std::array<std::array<std::int64_t, kMaxVertices>, kMaxVertices> weight{};
    std::array<std::array<bool, kMaxVertices>, kMaxVertices> edge{};
    std::array<std::array<bool, kMaxVertices>, kMaxVertices> reachable{};
    for (std::size_t from = 0; from < vertices; ++from) {
        reachable[from][from] = true;
        for (std::size_t to = 0; to < vertices; ++to) {
            const auto value = input[1 + from * vertices + to];
            if (value < -kMaxWeight || value > kMaxWeight) return -1;
            if (from != to && value != 0) {
                edge[from][to] = true;
                weight[from][to] = value;
                reachable[from][to] = true;
            }
        }
    }
    for (std::size_t intermediate = 0; intermediate < vertices; ++intermediate)
        for (std::size_t from = 0; from < vertices; ++from)
            for (std::size_t to = 0; to < vertices; ++to)
                reachable[from][to] = reachable[from][to] ||
                    (reachable[from][intermediate] && reachable[intermediate][to]);
    for (std::size_t from = 0; from < vertices; ++from)
        for (std::size_t to = 0; to < vertices; ++to)
            if (!reachable[from][to]) return -1;

    std::array<std::int64_t, kMaxVertices> potential{};
    for (std::size_t iteration = 1; iteration < vertices; ++iteration) {
        bool updated = false;
        for (std::size_t from = 0; from < vertices; ++from) {
            for (std::size_t to = 0; to < vertices; ++to) {
                if (!edge[from][to]) continue;
                const auto candidate = potential[from] + weight[from][to];
                if (candidate < potential[to]) {
                    potential[to] = candidate;
                    updated = true;
                }
            }
        }
        if (!updated) break;
    }
    for (std::size_t from = 0; from < vertices; ++from) {
        for (std::size_t to = 0; to < vertices; ++to) {
            if (!edge[from][to]) continue;
            if (potential[from] + weight[from][to] < potential[to]) return -1;
            if (weight[from][to] + potential[from] - potential[to] <= 0) return -1;
        }
    }

    std::array<std::array<std::int64_t, kMaxVertices>, kMaxVertices> reweighted{};
    for (std::size_t from = 0; from < vertices; ++from)
        for (std::size_t to = 0; to < vertices; ++to)
            if (edge[from][to]) reweighted[from][to] = weight[from][to] + potential[from] - potential[to];

    std::uint64_t result = kFnvOffset;
    for (std::size_t source = 0; source < vertices; ++source) {
        std::array<std::int64_t, kMaxVertices> distance;
        std::array<bool, kMaxVertices> visited{};
        distance.fill(kUnreachable);
        distance[source] = 0;
        for (std::size_t step = 0; step < vertices; ++step) {
            std::size_t current = vertices;
            for (std::size_t vertex = 0; vertex < vertices; ++vertex)
                if (!visited[vertex] && (current == vertices || distance[vertex] <= distance[current]))
                    current = vertex;
            if (current == vertices || distance[current] == kUnreachable) break;
            visited[current] = true;
            for (std::size_t next = 0; next < vertices; ++next) {
                if (!edge[current][next] || visited[next]) continue;
                const auto candidate = distance[current] + reweighted[current][next];
                if (candidate < distance[next]) distance[next] = candidate;
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
