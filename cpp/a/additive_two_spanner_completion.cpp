#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t N = 8, M = 28, INPUT = 59, INF = 9;
void put(std::uint8_t* out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        out[at + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
void distances(std::size_t n, std::size_t m, const std::array<std::size_t, M>& u,
               const std::array<std::size_t, M>& v, const std::array<bool, M>& selected,
               bool only_selected, std::array<std::array<std::size_t, N>, N>& d) {
    for (std::size_t a = 0; a < n; ++a)
        for (std::size_t b = 0; b < n; ++b) d[a][b] = a == b ? 0 : INF;
    for (std::size_t edge = 0; edge < m; ++edge) {
        if (only_selected && !selected[edge]) continue;
        d[u[edge]][v[edge]] = d[v[edge]][u[edge]] = 1;
    }
    for (std::size_t via = 0; via < n; ++via)
        for (std::size_t left = 0; left < n; ++left)
            for (std::size_t right = 0; right < n; ++right) {
                const auto candidate = d[left][via] + d[via][right];
                if (candidate < d[left][right]) d[left][right] = candidate;
            }
}
}

extern "C" std::int64_t additive_two_spanner_completion(
        const std::int64_t* input, std::size_t length, std::uint8_t* output,
        std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > INPUT) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > 8 || m64 < 0 || m64 > 28
            || length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::array<std::size_t, M> u{}, v{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto a = input[2 + 2 * edge], b = input[3 + 2 * edge];
        if (a < 0 || a >= b || b >= n64) return -1;
        u[edge] = static_cast<std::size_t>(a); v[edge] = static_cast<std::size_t>(b);
        for (std::size_t prior = 0; prior < edge; ++prior)
            if (u[prior] == u[edge] && v[prior] == v[edge]) return -1;
    }
    std::array<bool, M> selected{};
    std::array<std::array<std::size_t, N>, N> original{};
    distances(n, m, u, v, selected, false, original);
    for (std::size_t round = 0; round <= m; ++round) {
        std::array<std::array<std::size_t, N>, N> current{};
        distances(n, m, u, v, selected, true, current);
        std::size_t source = n, target = n;
        for (std::size_t a = 0; a < n && source == n; ++a)
            for (std::size_t b = a + 1; b < n; ++b)
                if (original[a][b] < INF && current[a][b] > original[a][b] + 2) {
                    source = a; target = b; break;
                }
        if (source == n) break;
        if (round == m) return -1;
        auto vertex = source;
        while (vertex != target) {
            std::size_t next = n;
            for (std::size_t neighbor = 0; neighbor < n; ++neighbor) {
                if (neighbor == vertex || original[neighbor][target] + 1 != original[vertex][target]) continue;
                for (std::size_t edge = 0; edge < m; ++edge)
                    if ((u[edge] == vertex && v[edge] == neighbor)
                            || (v[edge] == vertex && u[edge] == neighbor)) {
                        next = neighbor; selected[edge] = true; break;
                    }
                if (next != n) break;
            }
            if (next == n) return -1;
            vertex = next;
        }
    }
    std::size_t count = 0;
    for (std::size_t edge = 0; edge < m; ++edge) if (selected[edge]) ++count;
    const auto bytes = 8 * (1 + 2 * count);
    if (output == nullptr || capacity < bytes) return -2;
    put(output, 0, static_cast<std::int64_t>(count));
    std::size_t slot = 0;
    for (std::size_t edge = 0; edge < m; ++edge) if (selected[edge]) {
        put(output, 8 * (1 + 2 * slot), static_cast<std::int64_t>(u[edge]));
        put(output, 8 * (2 + 2 * slot), static_cast<std::int64_t>(v[edge]));
        ++slot;
    }
    return static_cast<std::int64_t>(bytes);
}
