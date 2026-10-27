#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int N = 8, MAX_M = 28, MAX_OUT = 1 + 2 * N + N * N;
void put_i64(std::uint8_t* out, std::size_t pos, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[pos + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
bool ancestor(const std::array<std::array<int, N>, N>& parent, int source, int a, int target) {
    int v = target;
    while (v >= 0) { if (v == a) return true; if (v == source) break; v = parent[source][v]; }
    return false;
}
}

extern "C" std::int64_t hub_labeling_greedy_order(const std::int64_t* input, std::size_t length,
                                                   std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 2 || length > 58) return -1;
    const auto n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > N || m0 < 0 || m0 > n0 * (n0 - 1) / 2 || length != 2 + 2 * static_cast<std::size_t>(m0)) return -1;
    const int n = static_cast<int>(n0), m = static_cast<int>(m0);
    std::array<std::array<bool, N>, N> adj{};
    std::int64_t pu = -1, pv = -1;
    for (int e = 0; e < m; ++e) {
        const auto u = input[2 + 2 * e], v = input[3 + 2 * e];
        if (u < 0 || v <= u || v >= n || (e && (u < pu || (u == pu && v <= pv)))) return -1;
        adj[u][v] = adj[v][u] = true; pu = u; pv = v;
    }
    std::array<std::array<int, N>, N> parent{}, depth{}, ways{};
    for (int s = 0; s < n; ++s) {
        parent[s].fill(-1); depth[s].fill(-1); ways[s].fill(0);
        std::array<int, N> queue{}; int head = 0, tail = 0;
        queue[tail++] = s; depth[s][s] = 0; ways[s][s] = 1;
        while (head < tail) {
            const int u = queue[head++];
            for (int v = 0; v < n; ++v) if (adj[u][v]) {
                if (depth[s][v] < 0) { depth[s][v] = depth[s][u] + 1; parent[s][v] = u; ways[s][v] = ways[s][u]; queue[tail++] = v; }
                else if (depth[s][v] == depth[s][u] + 1) ways[s][v] += ways[s][u]; if (ways[s][v] > 2) ways[s][v] = 2;
            }
        }
        for (int v = 0; v < n; ++v) if (depth[s][v] < 0 || ways[s][v] != 1) return -1;
    }
    std::array<std::array<bool, N>, N> active{};
    for (int s = 0; s < n; ++s) for (int t = 0; t < n; ++t) active[s][t] = true;
    std::array<int, N> order{}, rank{};
    for (int turn = 0; turn < n; ++turn) {
        std::array<int, N> count{};
        for (int s = 0; s < n; ++s) for (int t = 0; t < n; ++t) if (active[s][t]) {
            int x = t; while (x >= 0) { ++count[x]; if (x == s) break; x = parent[s][x]; }
        }
        int best = 0; for (int v = 1; v < n; ++v) if (count[v] > count[best]) best = v;
        order[turn] = best; rank[best] = turn;
        for (int s = 0; s < n; ++s) for (int t = 0; t < n; ++t) if (active[s][t] && ancestor(parent, s, best, t)) active[s][t] = false;
    }
    std::array<std::array<bool, N>, N> has{};
    std::array<std::array<int, N>, N> label_dist{};
    for (int u = 0; u < n; ++u) for (int v = u; v < n; ++v) {
        std::array<int, N> path{}; int len = 0, x = v;
        while (x >= 0) { path[len++] = x; if (x == u) break; x = parent[u][x]; }
        if (x < 0) return -1;
        int hub = path[0]; for (int i = 1; i < len; ++i) if (rank[path[i]] < rank[hub]) hub = path[i];
        has[u][hub] = has[v][hub] = true; label_dist[u][hub] = depth[u][hub]; label_dist[v][hub] = depth[v][hub];
    }
    std::array<std::int64_t, MAX_OUT> staged{}; std::size_t used = 0;
    staged[used++] = n; for (int i = 0; i < n; ++i) staged[used++] = order[i];
    for (int v = 0; v < n; ++v) {
        int count = 0; for (int h = 0; h < n; ++h) count += has[v][h];
        staged[used++] = count;
        for (int h = 0; h < n; ++h) if (has[v][h]) staged[used++] = h | (label_dist[v][h] << 8);
    }
    const std::size_t required = used * 8;
    if (!output || capacity < required) return -2;
    for (std::size_t i = 0; i < used; ++i) put_i64(output, i * 8, staged[i]);
    return static_cast<std::int64_t>(required);
}
