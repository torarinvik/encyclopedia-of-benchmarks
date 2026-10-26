#include <cstddef>
#include <cstdint>

namespace {
void put_i64(std::uint8_t* out, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t approximating_diameter_bfs(const std::int64_t* input, std::size_t length,
                                                     std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 2 || length > 242) return -1;
    const auto n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > 16 || m0 < 0 || m0 > 120 || length != 2 + 2 * static_cast<std::size_t>(m0)) return -1;
    const auto n = static_cast<std::size_t>(n0), m = static_cast<std::size_t>(m0);
    bool adj[16][16]{};
    for (std::size_t i = 0; i < m; ++i) {
        const auto u0 = input[2 + 2*i], v0 = input[3 + 2*i];
        if (u0 < 0 || v0 <= u0 || v0 >= n0) return -1;
        const auto u = static_cast<std::size_t>(u0), v = static_cast<std::size_t>(v0);
        if (adj[u][v]) return -1;
        adj[u][v] = adj[v][u] = true;
    }
    std::int64_t dist[16]; std::size_t queue[16];
    for (std::size_t i = 0; i < n; ++i) dist[i] = -1;
    dist[0] = 0; queue[0] = 0; std::size_t head = 0, tail = 1;
    while (head < tail) {
        const auto u = queue[head++];
        for (std::size_t v = 0; v < n; ++v) if (adj[u][v] && dist[v] < 0) {
            dist[v] = dist[u] + 1; queue[tail++] = v;
        }
    }
    if (tail != n) return -1;
    std::int64_t estimate = 0;
    for (std::size_t i = 0; i < n; ++i) if (dist[i] > estimate) estimate = dist[i];
    if (!output || capacity < 8) return -2;
    put_i64(output, estimate); return 8;
}
