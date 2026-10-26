/* Clean-room bounded GBBS Charikar profile; see package LICENSE.txt. */
#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" double gbbs_charikar_densest_subgraph(const std::int64_t *input, std::size_t length) {
    constexpr int MAX_N = 16, MAX_M = 64;
    constexpr double INVALID_RESULT = -1.0e300;
    if (input == nullptr || length < 2 || length > 2 + 2 * MAX_M) return INVALID_RESULT;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || length != 2 + 2 * static_cast<std::size_t>(m64)) return INVALID_RESULT;
    const int n = static_cast<int>(n64), m = static_cast<int>(m64);
    bool adjacent[MAX_N][MAX_N]{};
    int degree[MAX_N]{};
    for (int i = 0; i < m; ++i) {
        const auto u64 = input[2 + 2 * static_cast<std::size_t>(i)], v64 = input[3 + 2 * static_cast<std::size_t>(i)];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return INVALID_RESULT;
        const int u = static_cast<int>(u64), v = static_cast<int>(v64);
        if (adjacent[u][v]) return INVALID_RESULT;
        adjacent[u][v] = adjacent[v][u] = true; ++degree[u]; ++degree[v];
    }
    bool alive[MAX_N]{}; int order[MAX_N]{}, position[MAX_N]{};
    for (int v = 0; v < n; ++v) alive[v] = true;
    int used = 0;
    while (used < n) {
        int level = MAX_M;
        for (int v = 0; v < n; ++v) if (alive[v] && degree[v] < level) level = degree[v];
        for (;;) {
            int shell[MAX_N]{}, count = 0;
            for (int v = 0; v < n; ++v) if (alive[v] && degree[v] == level) shell[count++] = v;
            if (count == 0) break;
            for (int i = 0; i < count; ++i) { alive[shell[i]] = false; order[used++] = shell[i]; }
            for (int v = 0; v < n; ++v) if (alive[v]) {
                int removed = 0; for (int i = 0; i < count; ++i) removed += adjacent[v][shell[i]];
                degree[v] = std::max(degree[v] - removed, level);
            }
        }
    }
    for (int i = 0; i < n; ++i) position[order[i]] = i;
    double best = 0.0;
    for (int start = 0; start < n; ++start) {
        int edges = 0;
        for (int u = 0; u < n; ++u) if (position[u] >= start)
            for (int v = u + 1; v < n; ++v) if (position[v] >= start && adjacent[u][v]) ++edges;
        const double score = 2.0 * static_cast<double>(edges) / static_cast<double>(n - start);
        if (score > best) best = score;
    }
    return std::isfinite(best) ? best : INVALID_RESULT;
}
