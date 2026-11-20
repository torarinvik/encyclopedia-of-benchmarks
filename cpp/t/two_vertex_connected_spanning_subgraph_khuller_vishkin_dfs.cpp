#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t N = 8, M = 28, INPUT = 59;
void put(std::uint8_t* out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) { out[at + i] = static_cast<std::uint8_t>(bits & 255U); bits >>= 8; }
}
bool connected_without_vertex(std::size_t n, std::size_t m, const std::size_t* u,
                              const std::size_t* v, std::size_t removed) {
    bool seen[N]{}; std::size_t q[N]{}; std::size_t head = 0, tail = 1;
    const auto start = removed == 0 ? 1 : 0; q[0] = start; seen[start] = true;
    while (head < tail) {
        auto x = q[head++];
        for (std::size_t e = 0; e < m; ++e) {
            if (u[e] == removed || v[e] == removed) continue;
            std::size_t y = N;
            if (u[e] == x) y = v[e]; else if (v[e] == x) y = u[e];
            if (y < n && !seen[y]) { seen[y] = true; q[tail++] = y; }
        }
    }
    for (std::size_t i = 0; i < n; ++i) if (i != removed && !seen[i]) return false;
    return true;
}
bool earlier(std::size_t a, std::size_t b, const std::size_t* disc) { return disc[a] < disc[b]; }
}

extern "C" std::int64_t two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs(
        const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > INPUT) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 3 || n64 > 8 || m64 < 3 || m64 > 28 || length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::size_t u[M]{}, v[M]{};
    for (std::size_t e = 0; e < m; ++e) {
        const auto a = input[2 + 2 * e], b = input[3 + 2 * e];
        if (a < 0 || a >= b || b >= n64) return -1;
        u[e] = static_cast<std::size_t>(a); v[e] = static_cast<std::size_t>(b);
        for (std::size_t j = 0; j < e; ++j) if (u[j] == u[e] && v[j] == v[e]) return -1;
    }
    for (std::size_t removed = 0; removed < n; ++removed)
        if (!connected_without_vertex(n, m, u, v, removed)) return -1;

    std::size_t state[N]{}, disc[N]{}, low[N]{}, lowH[N]{}, savior[N]{};
    std::size_t parentEdge[N]{};
    bool selected[M]{};
    std::size_t sv[N]{}, sp[N]{}, sc[N]{};
    std::size_t tick = 1, top = 1;
    state[0] = 1; disc[0] = 0; low[0] = lowH[0] = savior[0] = 0;
    sv[0] = 0; sp[0] = N; sc[0] = 0;
    while (top > 0) {
        const auto frame = top - 1, x = sv[frame], parent = sp[frame];
        if (sc[frame] < m) {
            const auto e = sc[frame]++;
            std::size_t y = N;
            if (u[e] == x) y = v[e]; else if (v[e] == x) y = u[e];
            if (y == N) continue;
            if (state[y] == 0) {
                selected[e] = true; state[y] = 1; disc[y] = tick++; low[y] = lowH[y] = savior[y] = y;
                parentEdge[y] = e;
                sv[top] = y; sp[top] = x; sc[top] = 0; ++top;
            } else if (state[y] == 1 && y != parent && earlier(y, low[x], disc)) { low[x] = y; savior[x] = x; }
            continue;
        }
        state[x] = 2;
        if (parent < n && lowH[x] == x) {
            const auto a = savior[x], b = low[x], lo = a < b ? a : b, hi = a < b ? b : a;
            for (std::size_t e = 0; e < m; ++e) if (u[e] == lo && v[e] == hi) { selected[e] = true; break; }
            lowH[x] = low[x];
        }
        if (parent < n && lowH[x] == parent) {
            const auto a = savior[x], b = low[x], lo = a < b ? a : b, hi = a < b ? b : a;
            for (std::size_t e = 0; e < m; ++e) if (u[e] == lo && v[e] == hi) { selected[e] = true; break; }
            lowH[x] = low[x];
            if (savior[x] == x) selected[parentEdge[x]] = false;
        }
        --top;
        if (parent < n) {
            if (earlier(low[x], low[parent], disc)) { low[parent] = low[x]; savior[parent] = savior[x]; }
            if (earlier(lowH[x], lowH[parent], disc)) lowH[parent] = lowH[x];
        }
    }
    std::size_t count = 0; for (std::size_t e = 0; e < m; ++e) if (selected[e]) ++count;
    const auto bytes = 8 * (1 + 2 * count);
    if (output == nullptr || capacity < bytes) return -2;
    put(output, 0, static_cast<std::int64_t>(count)); std::size_t at = 8;
    for (std::size_t a = 0; a < n; ++a) for (std::size_t b = a + 1; b < n; ++b)
        for (std::size_t e = 0; e < m; ++e) if (selected[e] && u[e] == a && v[e] == b) {
            put(output, at, static_cast<std::int64_t>(a)); put(output, at + 8, static_cast<std::int64_t>(b)); at += 16;
        }
    return static_cast<std::int64_t>(bytes);
}
