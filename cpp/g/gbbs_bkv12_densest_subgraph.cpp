// Clean-room bounded GBBS BKV12 profile; see package LICENSE.txt.
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" double gbbs_bkv12_densest_subgraph(const std::int64_t* input, std::size_t length) {
    constexpr std::size_t N = 16, M = 64, MAX_INPUT = 2 + 2 * M + 2;
    constexpr double INVALID = -1.0e300;
    if (input == nullptr || length < 2 || length > MAX_INPUT) return INVALID;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 || length != 2 + 2 * static_cast<std::size_t>(m64)) return INVALID;
    const std::size_t n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    bool adjacent[N][N]{};
    std::int64_t degree[N]{};
    std::size_t edge_u[M]{}, edge_v[M]{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return INVALID;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (adjacent[u][v]) return INVALID;
        adjacent[u][v] = adjacent[v][u] = true;
        ++degree[u]; ++degree[v];
        edge_u[edge] = u; edge_v[edge] = v;
    }
    bool alive[N]{};
    for (std::size_t v = 0; v < n; ++v) alive[v] = true;
    std::size_t remaining = n;
    double best = 0.0;
    while (remaining > 0) {
        std::int64_t total = 0;
        for (std::size_t v = 0; v < n; ++v) if (alive[v]) total += degree[v];
        const double density = static_cast<double>(total) / static_cast<double>(remaining);
        if (density > best) best = density;
        bool removed[N]{};
        std::size_t count = 0;
        for (std::size_t v = 0; v < n; ++v) {
            if (alive[v] && 1000 * degree[v] * static_cast<std::int64_t>(remaining) <= 1001 * total) {
                removed[v] = true; ++count;
            }
        }
        if (count == 0) return INVALID;
        for (std::size_t v = 0; v < n; ++v) if (removed[v]) alive[v] = false;
        remaining -= count;
        for (std::size_t edge = 0; edge < m; ++edge) {
            const auto u = edge_u[edge], v = edge_v[edge];
            if (removed[u] && alive[v]) --degree[v];
            if (removed[v] && alive[u]) --degree[u];
        }
    }
    return std::isfinite(best) ? best : INVALID;
}
