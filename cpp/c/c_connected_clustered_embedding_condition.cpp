#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int N = 8, M = 18, F = 12, INPUT_MAX = 55;
struct Graph {
    int n = 0, c = 0, m = 0, f = 0, outer_u = 0, outer_v = 0, outer_face = -1;
    std::array<int, N> degree{}, mask{}, edge_u{}, edge_v{};
    std::array<std::array<int, N>, N> rotation{}, face_of{};
    std::array<std::array<bool, N>, N> adjacent{};
};

int find_root(std::array<int, F>& parent, int value) {
    while (parent[value] != value) {
        parent[value] = parent[parent[value]];
        value = parent[value];
    }
    return value;
}

bool connected(const Graph& g, int mask) {
    int start = -1, expected = 0;
    for (int v = 0; v < g.n; ++v) if ((mask >> v) & 1) {
        if (start < 0) start = v;
        ++expected;
    }
    if (expected <= 1) return true;
    std::array<bool, N> seen{};
    std::array<int, N> queue{};
    int head = 0, tail = 0;
    seen[start] = true; queue[tail++] = start;
    while (head < tail) {
        const int u = queue[head++];
        for (int v = 0; v < g.n; ++v)
            if (((mask >> v) & 1) && g.adjacent[u][v] && !seen[v]) {
                seen[v] = true; queue[tail++] = v;
            }
    }
    return tail == expected;
}

bool parse(const int64_t* input, std::size_t length, Graph& g) {
    if (input == nullptr || length < 4 || length > INPUT_MAX) return false;
    if (input[0] < 3 || input[0] > N || input[1] < 0 || input[1] > input[0] - 2) return false;
    g.n = static_cast<int>(input[0]); g.c = static_cast<int>(input[1]);
    if (input[2] < 0 || input[2] >= g.n || input[3] < 0 || input[3] >= g.n || input[2] == input[3]) return false;
    g.outer_u = static_cast<int>(input[2]); g.outer_v = static_cast<int>(input[3]);
    std::size_t offset = 4;
    int degree_sum = 0;
    for (int u = 0; u < g.n; ++u) {
        if (offset >= length) return false;
        const int64_t d64 = input[offset++];
        if (d64 < 1 || d64 >= g.n || offset + static_cast<std::size_t>(d64) > length) return false;
        const int d = static_cast<int>(d64);
        g.degree[u] = d; degree_sum += d;
        std::array<bool, N> row_seen{};
        for (int i = 0; i < d; ++i) {
            const int64_t raw = input[offset++];
            if (raw < 0 || raw >= g.n || raw == u || row_seen[static_cast<int>(raw)]) return false;
            const int v = static_cast<int>(raw);
            row_seen[v] = true; g.rotation[u][i] = v; g.adjacent[u][v] = true;
        }
    }
    if ((degree_sum & 1) || offset + static_cast<std::size_t>(g.c) != length) return false;
    g.m = degree_sum / 2;
    if (g.m < g.n - 1 || g.m > M) return false;
    int edge_count = 0;
    for (int u = 0; u < g.n; ++u) for (int v = 0; v < g.n; ++v) {
        if (g.adjacent[u][v] != g.adjacent[v][u]) return false;
        if (u < v && g.adjacent[u][v]) {
            g.edge_u[edge_count] = u; g.edge_v[edge_count++] = v;
        }
    }
    if (edge_count != g.m || !g.adjacent[g.outer_u][g.outer_v]) return false;
    const int full = (1 << g.n) - 1;
    for (int i = 0; i < g.c; ++i) {
        const int64_t raw = input[offset++];
        if (raw <= 0 || raw >= full) return false;
        const int mask = static_cast<int>(raw);
        int bit_count = 0;
        for (int v = 0; v < g.n; ++v) bit_count += (mask >> v) & 1;
        if (bit_count < 2) return false;
        for (int j = 0; j < i; ++j) {
            if (g.mask[j] == mask) return false;
            const int common = g.mask[j] & mask;
            if (common && common != g.mask[j] && common != mask) return false;
        }
        g.mask[i] = mask;
        if (!connected(g, mask)) return false;
    }
    if (!connected(g, full)) return false;
    for (auto& row : g.face_of) row.fill(-1);
    g.f = 0;
    for (int e = 0; e < g.m; ++e) {
        for (int side = 0; side < 2; ++side) {
            const int start_u = side == 0 ? g.edge_u[e] : g.edge_v[e];
            const int start_v = side == 0 ? g.edge_v[e] : g.edge_u[e];
            if (g.face_of[start_u][start_v] >= 0) continue;
            if (g.f >= F) return false;
            std::array<std::array<bool, N>, N> local{};
            int u = start_u, v = start_v, steps = 0;
            for (;;) {
                if (local[u][v] || g.face_of[u][v] >= 0) return false;
                local[u][v] = true; g.face_of[u][v] = g.f;
                int at = -1;
                for (int i = 0; i < g.degree[v]; ++i) if (g.rotation[v][i] == u) { at = i; break; }
                if (at < 0) return false;
                const int next = g.rotation[v][(at + 1) % g.degree[v]];
                u = v; v = next;
                if (u == start_u && v == start_v) break;
                if (++steps > 2 * g.m) return false;
            }
            ++g.f;
        }
    }
    if (g.f != g.m - g.n + 2) return false;
    for (int u = 0; u < g.n; ++u) for (int v = 0; v < g.n; ++v)
        if (g.adjacent[u][v] && g.face_of[u][v] < 0) return false;
    g.outer_face = g.face_of[g.outer_u][g.outer_v];
    return g.outer_face >= 0;
}
}

extern "C" int64_t c_connected_clustered_embedding_condition(const int64_t* input, std::size_t length) {
    Graph g{};
    if (!parse(input, length, g)) return -1;
    for (int ci = 0; ci < g.c; ++ci) {
        std::array<int, F> parent{};
        for (int f = 0; f < g.f; ++f) parent[f] = f;
        const int mask = g.mask[ci];
        for (int e = 0; e < g.m; ++e) {
            const int u = g.edge_u[e], v = g.edge_v[e];
            if (((mask >> u) & 1) && ((mask >> v) & 1)) continue;
            parent[find_root(parent, g.face_of[u][v])] = find_root(parent, g.face_of[v][u]);
        }
        const int outside = find_root(parent, g.outer_face);
        for (int v = 0; v < g.n; ++v) if (!((mask >> v) & 1)) {
            bool incident = false;
            for (int u = 0; u < g.n; ++u) if (g.adjacent[v][u]) {
                incident = true;
                if (find_root(parent, g.face_of[v][u]) != outside) return 0;
            }
            if (!incident) return -1;
        }
        for (int e = 0; e < g.m; ++e) {
            const int u = g.edge_u[e], v = g.edge_v[e];
            if (((mask >> u) & 1) && ((mask >> v) & 1)) continue;
            if (find_root(parent, g.face_of[u][v]) != outside) return 0;
        }
    }
    return 1;
}
