/* Improved shortest augmenting path with reverse labels and the gap rule. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t NMAX = 8, MMAX = 24, INPUT_MAX = 4 + 3 * MMAX + 1;
constexpr std::int64_t FLOW_MAX = 2400;
struct State {
    std::size_t n, sink;
    std::int64_t residual[NMAX * NMAX]{};
    std::int64_t distance[NMAX]{}, gap[NMAX + 1]{};
    std::size_t current[NMAX]{};
    bool stopped = false;
};
std::int64_t dfs(State& s, std::size_t u, std::int64_t amount) {
    if (u == s.sink) return amount;
    while (s.current[u] < s.n) {
        const auto v = s.current[u], edge = u * NMAX + v;
        if (s.residual[edge] > 0 && s.distance[u] == s.distance[v] + 1) {
            const auto limit = amount < s.residual[edge] ? amount : s.residual[edge];
            const auto sent = dfs(s, v, limit);
            if (sent > 0) { s.residual[edge] -= sent; s.residual[v * NMAX + u] += sent; return sent; }
            if (s.stopped) return 0;
        }
        ++s.current[u];
    }
    const auto old = s.distance[u];
    auto best = static_cast<std::int64_t>(s.n);
    for (std::size_t v = 0; v < s.n; ++v)
        if (s.residual[u * NMAX + v] > 0 && s.distance[v] < best) best = s.distance[v];
    const auto replacement = best + 1 < static_cast<std::int64_t>(s.n) ? best + 1 : static_cast<std::int64_t>(s.n);
    --s.gap[static_cast<std::size_t>(old)]; s.distance[u] = replacement;
    ++s.gap[static_cast<std::size_t>(replacement)]; s.current[u] = 0;
    if (old < static_cast<std::int64_t>(s.n) && s.gap[static_cast<std::size_t>(old)] == 0) s.stopped = true;
    return 0;
}
}

extern "C" std::int64_t isap_maxflow(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 4 || length > INPUT_MAX) return -1;
    const auto nv = input[0], mv = input[1], sv = input[2], tv = input[3];
    if (nv < 2 || nv > static_cast<std::int64_t>(NMAX) || mv < 0 || mv > static_cast<std::int64_t>(MMAX) ||
        sv < 0 || sv >= nv || tv < 0 || tv >= nv || sv == tv || length != 4 + 3 * static_cast<std::size_t>(mv)) return -1;
    State s{}; s.n = static_cast<std::size_t>(nv); s.sink = static_cast<std::size_t>(tv);
    for (std::size_t e = 0; e < static_cast<std::size_t>(mv); ++e) {
        const auto u = input[4 + 3 * e], v = input[5 + 3 * e], c = input[6 + 3 * e];
        if (u < 0 || u >= nv || v < 0 || v >= nv || u == v || c < 0 || c > 100) return -1;
        s.residual[static_cast<std::size_t>(u) * NMAX + static_cast<std::size_t>(v)] += c;
    }
    std::size_t queue[NMAX]{}, head = 0, tail = 1;
    for (std::size_t v = 0; v < s.n; ++v) s.distance[v] = static_cast<std::int64_t>(s.n);
    s.distance[s.sink] = 0; queue[0] = s.sink;
    while (head < tail) { const auto v = queue[head++]; for (std::size_t p = 0; p < s.n; ++p)
        if (s.distance[p] == static_cast<std::int64_t>(s.n) && s.residual[p * NMAX + v] > 0) { s.distance[p] = s.distance[v] + 1; queue[tail++] = p; } }
    const auto source = static_cast<std::size_t>(sv);
    if (s.distance[source] >= static_cast<std::int64_t>(s.n)) return 0;
    for (std::size_t v = 0; v < s.n; ++v) ++s.gap[static_cast<std::size_t>(s.distance[v])];
    std::int64_t flow = 0;
    while (s.distance[source] < static_cast<std::int64_t>(s.n) && !s.stopped) flow += dfs(s, source, FLOW_MAX);
    return flow;
}
