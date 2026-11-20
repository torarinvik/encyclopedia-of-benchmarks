#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t N = 8, M = 28, INPUT = 60;
void put(std::uint8_t* out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) { out[at + i] = static_cast<std::uint8_t>(bits & 255U); bits >>= 8; }
}
}

extern "C" std::int64_t nagamochi_ibaraki_sparse_k_connectivity_certificate(
        const std::int64_t* input, std::size_t length, std::uint8_t* output,
        std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > INPUT) return -1;
    const auto n64 = input[0], m64 = input[1], k64 = input[2];
    if (n64 < 3 || n64 > 8 || m64 < 0 || m64 > 28 || k64 < 1 || k64 > 3
            || length != 3 + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    const auto k = static_cast<std::size_t>(k64);
    std::size_t u[M]{}, v[M]{}, incident[N][N]{}, degree[N]{};
    for (std::size_t e = 0; e < m; ++e) {
        const auto a = input[3 + 2 * e], b = input[4 + 2 * e];
        if (a < 0 || a >= b || b >= n64) return -1;
        u[e] = static_cast<std::size_t>(a); v[e] = static_cast<std::size_t>(b);
        for (std::size_t j = 0; j < e; ++j) if (u[j] == u[e] && v[j] == v[e]) return -1;
        incident[u[e]][degree[u[e]]++] = e; incident[v[e]][degree[v[e]]++] = e;
    }
    const auto bytes = 8 * (m + 1);
    if (output == nullptr || capacity < bytes) return -2;
    std::size_t rank[N]{}, layer[M]{};
    bool scanned_vertex[N]{}, scanned_edge[M]{};
    for (std::size_t step = 0; step < n; ++step) {
        auto x = n;
        for (std::size_t vertex = 0; vertex < n; ++vertex)
            if (!scanned_vertex[vertex] && (x == n || rank[vertex] > rank[x])) x = vertex;
        for (std::size_t slot = 0; slot < degree[x]; ++slot) {
            const auto e = incident[x][slot];
            if (scanned_edge[e]) continue;
            const auto y = u[e] == x ? v[e] : u[e];
            layer[e] = rank[y] + 1;
            if (rank[x] == rank[y]) ++rank[x];
            ++rank[y];
            scanned_edge[e] = true;
        }
        scanned_vertex[x] = true;
    }
    put(output, 0, static_cast<std::int64_t>(m));
    for (std::size_t e = 0; e < m; ++e)
        put(output, 8 * (e + 1), static_cast<std::int64_t>(layer[e] <= k ? layer[e] : 0));
    return static_cast<std::int64_t>(bytes);
}
