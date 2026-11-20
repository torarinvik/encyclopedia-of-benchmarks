#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t N = 8, M = 28, INPUT = 59;

void put(std::uint8_t* out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        out[at + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}

bool biconnected(std::size_t n, std::size_t m, const std::array<std::size_t, M>& u,
                 const std::array<std::size_t, M>& v, const std::array<bool, M>& active) {
    for (std::size_t removed = 0; removed < n; ++removed) {
        std::array<bool, N> seen{};
        std::array<std::size_t, N> queue{};
        const auto start = removed == 0 ? 1U : 0U;
        std::size_t head = 0, tail = 1;
        seen[start] = true;
        queue[0] = start;
        while (head < tail) {
            const auto current = queue[head++];
            for (std::size_t e = 0; e < m; ++e) {
                if (!active[e] || u[e] == removed || v[e] == removed) continue;
                std::size_t next = N;
                if (u[e] == current) next = v[e];
                else if (v[e] == current) next = u[e];
                if (next < n && !seen[next]) { seen[next] = true; queue[tail++] = next; }
            }
        }
        for (std::size_t vertex = 0; vertex < n; ++vertex)
            if (vertex != removed && !seen[vertex]) return false;
    }
    return true;
}
}

extern "C" std::int64_t cheriyan_thurimella_two_vertex_connected_augmentation(
        const std::int64_t* input, std::size_t length, std::uint8_t* output,
        std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > INPUT) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 3 || n64 > 8 || m64 < 3 || m64 > 28
            || length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::array<std::size_t, M> u{}, v{};
    for (std::size_t e = 0; e < m; ++e) {
        const auto a = input[2 + 2 * e], b = input[3 + 2 * e];
        if (a < 0 || a >= b || b >= n64) return -1;
        u[e] = static_cast<std::size_t>(a); v[e] = static_cast<std::size_t>(b);
        for (std::size_t prior = 0; prior < e; ++prior)
            if (u[prior] == u[e] && v[prior] == v[e]) return -1;
    }
    std::array<bool, M> active{};
    for (std::size_t e = 0; e < m; ++e) active[e] = true;
    if (!biconnected(n, m, u, v, active)) return -1;

    const std::size_t states = std::size_t{1} << n;
    std::array<int, 1 << N> best{};
    std::array<int, 1 << N> choice{};
    choice.fill(-1);
    for (std::size_t mask = 1; mask < states; ++mask) {
        std::size_t first = 0;
        while (((mask >> first) & 1U) == 0) ++first;
        for (std::size_t e = 0; e < m; ++e) {
            std::size_t other = N;
            if (u[e] == first) other = v[e];
            else if (v[e] == first) other = u[e];
            if (other == N || ((mask >> other) & 1U) == 0) continue;
            const auto rest = mask & ~(std::size_t{1} << first) & ~(std::size_t{1} << other);
            const auto candidate = 1 + best[rest];
            if (candidate > best[mask]) { best[mask] = candidate; choice[mask] = static_cast<int>(e); }
        }
        const auto rest = mask & ~(std::size_t{1} << first);
        if (best[rest] > best[mask]) { best[mask] = best[rest]; choice[mask] = -1; }
    }

    std::array<bool, M> cover{};
    std::array<bool, N> covered{};
    auto mask = states - 1;
    while (mask != 0) {
        std::size_t first = 0;
        while (((mask >> first) & 1U) == 0) ++first;
        const auto edge = choice[mask];
        if (edge < 0) { mask &= ~(std::size_t{1} << first); continue; }
        const auto e = static_cast<std::size_t>(edge);
        cover[e] = true; covered[u[e]] = covered[v[e]] = true;
        mask &= ~(std::size_t{1} << u[e]) & ~(std::size_t{1} << v[e]);
    }
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        if (covered[vertex]) continue;
        for (std::size_t e = 0; e < m; ++e) if (u[e] == vertex || v[e] == vertex) {
            cover[e] = true; covered[u[e]] = covered[v[e]] = true; break;
        }
    }
    for (std::size_t e = 0; e < m; ++e) if (!cover[e]) {
        active[e] = false;
        if (!biconnected(n, m, u, v, active)) active[e] = true;
    }
    std::size_t count = 0;
    for (std::size_t e = 0; e < m; ++e) if (active[e]) ++count;
    const auto bytes = 8 * (1 + 2 * count);
    if (output == nullptr || capacity < bytes) return -2;
    put(output, 0, static_cast<std::int64_t>(count));
    std::size_t slot = 0;
    for (std::size_t e = 0; e < m; ++e) if (active[e]) {
        put(output, 8 * (1 + 2 * slot), static_cast<std::int64_t>(u[e]));
        put(output, 8 * (2 + 2 * slot), static_cast<std::int64_t>(v[e]));
        ++slot;
    }
    return static_cast<std::int64_t>(bytes);
}
