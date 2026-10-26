// Clean-room bounded Brandes profile; see package LICENSE.txt.
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t gapbs_betweenness_centrality(const std::int64_t* input,
                                                       std::size_t length) noexcept {
    constexpr std::size_t MaxN = 8;
    if (!input || length < 12 || length > 74) return -1;
    const auto n64 = input[0], k64 = input[1];
    if (n64 < 3 || n64 > 8 || k64 < 1 || k64 > n64) return -1;
    const auto n = static_cast<std::size_t>(n64), k = static_cast<std::size_t>(k64);
    if (length != 2 + k + n * n) return -1;
    std::array<std::size_t, MaxN> sources{};
    for (std::size_t i = 0; i < k; ++i) {
        if (input[2 + i] < 0 || input[2 + i] >= n64) return -1;
        sources[i] = static_cast<std::size_t>(input[2 + i]);
        for (std::size_t j = 0; j < i; ++j) if (sources[j] == sources[i]) return -1;
    }
    std::array<std::array<int, MaxN>, MaxN> adjacency{};
    for (std::size_t u = 0; u < n; ++u) for (std::size_t v = 0; v < n; ++v) {
        const auto edge = input[2 + k + u * n + v];
        if ((edge != 0 && edge != 1) || (u == v && edge != 0)) return -1;
        adjacency[u][v] = static_cast<int>(edge);
    }
    for (std::size_t u = 0; u < n; ++u)
        for (std::size_t v = u + 1; v < n; ++v)
            if (adjacency[u][v] != adjacency[v][u]) return -1;

    std::array<float, MaxN> scores{};
    for (std::size_t si = 0; si < k; ++si) {
        std::array<int, MaxN> depth{};
        std::array<std::size_t, MaxN> queue{};
        std::array<double, MaxN> paths{};
        std::array<float, MaxN> delta{};
        depth.fill(-1);
        const auto source = sources[si];
        depth[source] = 0; paths[source] = 1.0;
        std::size_t head = 0, tail = 0;
        queue[tail++] = source;
        while (head < tail) {
            const auto u = queue[head++];
            for (std::size_t v = 0; v < n; ++v) if (adjacency[u][v]) {
                if (depth[v] == -1) { depth[v] = depth[u] + 1; queue[tail++] = v; }
                if (depth[v] == depth[u] + 1) paths[v] += paths[u];
            }
        }
        int max_depth = 0;
        for (std::size_t v = 0; v < n; ++v) if (depth[v] > max_depth) max_depth = depth[v];
        for (int d = max_depth; d >= 0; --d) for (std::size_t u = 0; u < n; ++u) if (depth[u] == d) {
            float delta_u = 0.0f;
            for (std::size_t v = 0; v < n; ++v) if (adjacency[u][v] && depth[v] == d + 1) {
                const float one_plus = 1.0f + delta[v];
                const double contribution = (paths[u] / paths[v]) * static_cast<double>(one_plus);
                delta_u = static_cast<float>(static_cast<double>(delta_u) + contribution);
            }
            delta[u] = delta_u;
            scores[u] = static_cast<float>(static_cast<double>(scores[u]) + static_cast<double>(delta_u));
        }
    }
    float biggest = 0.0f;
    for (std::size_t v = 0; v < n; ++v) if (scores[v] > biggest) biggest = scores[v];
    if (!(biggest > 0.0f)) return -1;
    std::int64_t checksum = 0;
    for (std::size_t v = 0; v < n; ++v) {
        const float normalized = scores[v] / biggest;
        const auto qscore = static_cast<std::int64_t>(static_cast<double>(normalized) * 1000.0 + 0.5);
        checksum += static_cast<std::int64_t>(v + 1) * qscore;
    }
    return checksum;
}
