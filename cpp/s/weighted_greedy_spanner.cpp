#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 8, MaxM = 28, MaxInput = 88;
struct Edge { std::int64_t u, v, weight; std::size_t original; };
}

extern "C" std::int64_t weighted_greedy_spanner(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 3 || length > MaxInput) return -1;
    const auto n64 = input[0], m64 = input[1], k = input[2];
    if (n64 < 2 || n64 > static_cast<std::int64_t>(MaxN) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(MaxM) || k < 1 || k > 3 ||
        length != 3 + 3 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::array<Edge, MaxM> edges{};
    std::array<std::uint8_t, MaxM> selected{};
    std::array<std::array<std::int64_t, MaxN>, MaxN> adjacency{};
    for (std::size_t i = 0; i < m; ++i) {
        auto& e = edges[i];
        e = {input[3 + 3 * i], input[4 + 3 * i], input[5 + 3 * i], i};
        if (e.u < 0 || e.v <= e.u || e.v >= n64 || e.weight < 1 || e.weight > 32) return -1;
        for (std::size_t j = 0; j < i; ++j)
            if (edges[j].u == e.u && edges[j].v == e.v) return -1;
    }
    for (std::size_t i = 1; i < m; ++i) {
        const auto key = edges[i];
        auto pos = i;
        while (pos > 0) {
            const auto& prev = edges[pos - 1];
            if (prev.weight < key.weight || (prev.weight == key.weight && prev.u < key.u) ||
                (prev.weight == key.weight && prev.u == key.u && prev.v <= key.v)) break;
            edges[pos] = edges[pos - 1]; --pos;
        }
        edges[pos] = key;
    }
    if (!output || capacity < m) return -2;
    for (std::size_t rank = 0; rank < m; ++rank) {
        const auto e = edges[rank];
        std::array<std::int64_t, MaxN> distance{};
        std::array<bool, MaxN> settled{};
        distance.fill(INT64_C(1) << 60);
        const auto source = static_cast<std::size_t>(e.u), target = static_cast<std::size_t>(e.v);
        distance[source] = 0;
        for (std::size_t step = 0; step < n; ++step) {
            std::size_t vertex = n;
            for (std::size_t v = 0; v < n; ++v)
                if (!settled[v] && (vertex == n || distance[v] < distance[vertex])) vertex = v;
            if (vertex == n || distance[vertex] == (INT64_C(1) << 60)) break;
            settled[vertex] = true;
            for (std::size_t v = 0; v < n; ++v)
                if (adjacency[vertex][v] > 0 && distance[v] > distance[vertex] + adjacency[vertex][v])
                    distance[v] = distance[vertex] + adjacency[vertex][v];
        }
        if (distance[target] > (2 * k - 1) * e.weight) {
            selected[e.original] = 1;
            adjacency[source][target] = adjacency[target][source] = e.weight;
        }
    }
    for (std::size_t i = 0; i < m; ++i) output[i] = selected[i];
    return static_cast<std::int64_t>(m);
}
