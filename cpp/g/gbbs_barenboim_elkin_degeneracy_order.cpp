// Clean-room bounded GBBS Barenboim-Elkin profile; see package LICENSE.txt.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t N = 20, M = 190, INPUT = 2 + 2 * M;
void store_i64_le(std::uint8_t* output, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { output[byte] = static_cast<std::uint8_t>(bits & 255u); bits >>= 8; }
}
}

extern "C" std::int64_t gbbs_barenboim_elkin_degeneracy_order(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > INPUT) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > 20 || m64 < 0 || m64 > 190 || length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::array<std::array<bool, N>, N> adjacent{};
    std::array<std::int64_t, N> initial_degree{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = true;
        ++initial_degree[u]; ++initial_degree[v];
    }
    if (output == nullptr || capacity < 8 * n) return -2;
    auto degree = initial_degree;
    std::array<bool, N> alive{};
    for (std::size_t v = 0; v < n; ++v) alive[v] = true;
    std::size_t remaining = n;
    std::int64_t best_num = 0, best_den = 1;
    while (remaining > 0) {
        std::int64_t total = 0;
        for (std::size_t v = 0; v < n; ++v) if (alive[v]) total += degree[v];
        if (total * best_den > best_num * static_cast<std::int64_t>(remaining)) { best_num = total; best_den = static_cast<std::int64_t>(remaining); }
        std::array<bool, N> removed{};
        std::size_t count = 0;
        for (std::size_t v = 0; v < n; ++v) if (alive[v] && 10 * degree[v] * static_cast<std::int64_t>(remaining) <= 11 * total) { removed[v] = true; ++count; }
        if (count == 0) return -1;
        for (std::size_t v = 0; v < n; ++v) if (removed[v]) alive[v] = false;
        remaining -= count;
        for (std::size_t v = 0; v < n; ++v) if (alive[v]) {
            std::int64_t dec = 0;
            for (std::size_t u = 0; u < n; ++u) dec += removed[u] && adjacent[v][u];
            degree[v] -= dec;
        }
    }
    auto cutoff = std::max<std::int64_t>((best_num + 10 * best_den - 1) / (10 * best_den), 1);
    degree = initial_degree;
    alive.fill(false);
    for (std::size_t v = 0; v < n; ++v) alive[v] = true;
    std::array<std::size_t, N> order{};
    std::size_t used = 0;
    while (used < n) {
        std::array<std::size_t, N> shell{};
        std::size_t count = 0;
        for (std::size_t v = 0; v < n; ++v) if (alive[v] && degree[v] < cutoff) shell[count++] = v;
        if (count == 0) for (std::size_t v = 0; v < n; ++v) if (alive[v]) { shell[count++] = v; break; }
        for (std::size_t i = 0; i < count; ++i) { alive[shell[i]] = false; order[used++] = shell[i]; }
        for (std::size_t v = 0; v < n; ++v) if (alive[v]) {
            std::int64_t dec = 0;
            for (std::size_t i = 0; i < count; ++i) dec += adjacent[v][shell[i]];
            degree[v] -= dec;
        }
    }
    std::array<std::int64_t, N> rank{};
    for (std::size_t i = 0; i < n; ++i) rank[order[i]] = static_cast<std::int64_t>(i);
    for (std::size_t v = 0; v < n; ++v) store_i64_le(output + 8 * v, rank[v]);
    return static_cast<std::int64_t>(8 * n);
}
