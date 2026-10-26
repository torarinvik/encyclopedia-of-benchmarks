// Clean-room bounded GBBS GreedyPlusPlus profile; see package LICENSE.txt.
#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" double gbbs_greedy_plus_plus_densest_subgraph(const std::int64_t* input, std::size_t length) {
    constexpr std::size_t N = 16, M = 64, MAX_INPUT = 2 + 2 * M + 2;
    constexpr double INVALID = -1.0e300;
    if (input == nullptr || length < 2 || length > MAX_INPUT) return INVALID;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 10 || n64 > 16 || m64 < 0 || m64 > 64 || length != 2 + 2 * static_cast<std::size_t>(m64)) return INVALID;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    bool adjacent[N][N]{};
    std::int64_t load[N]{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return INVALID;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (adjacent[u][v]) return INVALID;
        adjacent[u][v] = adjacent[v][u] = true;
        ++load[u]; ++load[v];
    }
    double best = 0.0;
    for (std::size_t round = 0; round < 20; ++round) {
        std::int64_t degree[N];
        bool alive[N]{};
        std::size_t order[N]{}, position[N]{};
        for (std::size_t v = 0; v < n; ++v) { degree[v] = load[v]; alive[v] = true; }
        std::size_t used = 0;
        while (used < n) {
            auto level = std::numeric_limits<std::int64_t>::max();
            for (std::size_t v = 0; v < n; ++v) if (alive[v] && degree[v] < level) level = degree[v];
            std::size_t shell[N]{}, count = 0;
            for (std::size_t v = 0; v < n; ++v) if (alive[v] && degree[v] == level) shell[count++] = v;
            for (std::size_t i = 0; i < count; ++i) { alive[shell[i]] = false; order[used++] = shell[i]; }
            for (std::size_t v = 0; v < n; ++v) if (alive[v]) {
                std::int64_t removed = 0;
                for (std::size_t i = 0; i < count; ++i) removed += adjacent[v][shell[i]];
                degree[v] = std::max(degree[v] - removed, level);
            }
        }
        for (std::size_t i = 0; i < n; ++i) position[order[i]] = i;
        std::int64_t density_above[N]{};
        for (std::size_t v = 0; v < n; ++v) {
            std::int64_t later = 0;
            for (std::size_t u = 0; u < n; ++u) if (adjacent[v][u] && position[u] > position[v]) ++later;
            density_above[position[v]] = 2 * later;
            load[v] += later;
        }
        std::int64_t suffix_sum = 0;
        for (std::size_t i = n; i-- > 0;) {
            suffix_sum += density_above[i];
            best = std::max(best, static_cast<double>(suffix_sum) / static_cast<double>(n - i));
        }
    }
    return std::isfinite(best) ? best : INVALID;
}
