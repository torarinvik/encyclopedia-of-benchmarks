// Clean-room bounded port of GAPBS OrderedCount; see package LICENSE.txt.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t gapbs_ordered_triangle_count(const std::int64_t* input,
                                                      std::size_t length) noexcept {
    constexpr std::size_t MaxN = 16;
    if (!input || length < 2 || length > 1 + MaxN * MaxN) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + n * n) return -1;
    std::array<std::array<std::int64_t, MaxN>, MaxN> adjacency{};
    std::array<std::array<std::size_t, MaxN>, MaxN> neighbors{};
    std::array<std::size_t, MaxN> degree{};
    for (std::size_t u = 0; u < n; ++u) {
        for (std::size_t v = 0; v < n; ++v) {
            const auto edge = input[1 + u * n + v];
            if ((edge != 0 && edge != 1) || (u == v && edge != 0)) return -1;
            adjacency[u][v] = edge;
        }
    }
    for (std::size_t u = 0; u < n; ++u)
        for (std::size_t v = u + 1; v < n; ++v)
            if (adjacency[u][v] != adjacency[v][u]) return -1;
    for (std::size_t u = 0; u < n; ++u)
        for (std::size_t v = 0; v < n; ++v)
            if (adjacency[u][v] != 0) neighbors[u][degree[u]++] = v;

    std::int64_t total = 0;
    for (std::size_t u = 0; u < n; ++u) {
        for (std::size_t vi = 0; vi < degree[u]; ++vi) {
            const auto v = neighbors[u][vi];
            if (v > u) break;
            std::size_t edge_pos = 0;
            for (std::size_t wi = 0; wi < degree[u]; ++wi) {
                const auto w = neighbors[u][wi];
                if (w > v) break;
                while (edge_pos < degree[v] && neighbors[v][edge_pos] < w) ++edge_pos;
                if (edge_pos < degree[v] && neighbors[v][edge_pos] == w) ++total;
            }
        }
    }
    return total;
}
