#include <cstddef>
#include <cstdint>

namespace {
constexpr int NMAX = 8, MMAX = 16, FMAX = 10, IMAX = 79;
constexpr int VMAX = NMAX + FMAX + 2, EMAX = 200;
constexpr std::int64_t INF = std::int64_t(1) << 60;
struct Edge { int from, to, reverse; std::int64_t cap, cost; };

bool add(Edge *edges, int &count, int u, int v, std::int64_t cap, std::int64_t cost) {
    if (count + 2 > EMAX) return false;
    int e = count;
    edges[e] = {u, v, e + 1, cap, cost};
    edges[e + 1] = {v, u, e, 0, -cost};
    count += 2;
    return true;
}
bool connected(const bool adj[NMAX][NMAX], int n, int removed) {
    int seen[NMAX] = {}, stack[NMAX], top = 0, count = 0;
    int start = removed == 0 ? 1 : 0;
    seen[start] = 1; stack[top++] = start;
    while (top) {
        int u = stack[--top]; ++count;
        for (int v = 0; v < n; ++v)
            if (v != removed && adj[u][v] && !seen[v]) { seen[v] = 1; stack[top++] = v; }
    }
    return count == n - (removed >= 0);
}
}

extern "C" std::int64_t orthogonal_drawing_minimum_bends(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 4 || length > IMAX) return -1;
    auto n0 = input[0], m0 = input[1], f0 = input[2], outside0 = input[3];
    if (n0 < 3 || n0 > NMAX || m0 < n0 || m0 > MMAX || f0 < 2 || f0 > FMAX ||
        f0 != m0 - n0 + 2 || outside0 < 0 || outside0 >= f0) return -1;
    int n = int(n0), m = int(m0), f = int(f0), outside = int(outside0);
    bool adj[NMAX][NMAX] = {};
    int degree[NMAX] = {}, eu[MMAX], ev[MMAX], uses[NMAX][NMAX] = {};
    std::size_t p = 4;
    for (int e = 0; e < m; ++e) {
        if (p + 2 > length) return -1;
        auto u0 = input[p++], v0 = input[p++];
        if (u0 < 0 || u0 >= v0 || v0 >= n) return -1;
        int u = int(u0), v = int(v0);
        if (adj[u][v] || (e && (u < eu[e-1] || (u == eu[e-1] && v <= ev[e-1])))) return -1;
        adj[u][v] = adj[v][u] = true; ++degree[u]; ++degree[v]; eu[e] = u; ev[e] = v;
    }
    for (int v = 0; v < n; ++v) if (degree[v] < 2 || degree[v] > 4) return -1;
    int face[FMAX][NMAX] = {}, width[FMAX] = {};
    bool link_adj[NMAX][NMAX][NMAX] = {};
    int link_degree[NMAX][NMAX] = {};
    for (int g = 0; g < f; ++g) {
        if (p >= length) return -1;
        auto w0 = input[p++];
        if (w0 < 3 || w0 > n || p + std::size_t(w0) > length) return -1;
        width[g] = int(w0);
        bool row[NMAX] = {};
        for (int i = 0; i < width[g]; ++i) {
            auto x0 = input[p++];
            if (x0 < 0 || x0 >= n || row[x0]) return -1;
            face[g][i] = int(x0); row[x0] = true;
        }
        for (int i = 0; i < width[g]; ++i) {
            int u = face[g][i], v = face[g][(i + 1) % width[g]];
            if (!adj[u][v]) return -1;
            ++uses[u][v];
        }
        for (int i = 0; i < width[g]; ++i) {
            int center = face[g][i];
            int before = face[g][(i + width[g] - 1) % width[g]];
            int after = face[g][(i + 1) % width[g]];
            if (before == after) return -1;
            link_adj[center][before][after] = link_adj[center][after][before] = true;
            ++link_degree[center][before]; ++link_degree[center][after];
        }
    }
    if (p != length || n - m + f != 2 || !connected(adj, n, -1)) return -1;
    for (int v = 0; v < n; ++v) if (!connected(adj, n, v)) return -1;
    int fa[MMAX] = {}, fb[MMAX] = {}, count_face[MMAX] = {};
    for (int e = 0; e < m; ++e) if (uses[eu[e]][ev[e]] != 1 || uses[ev[e]][eu[e]] != 1) return -1;
    for (int center = 0; center < n; ++center) {
        int start = -1, incident_count = 0;
        for (int neighbor = 0; neighbor < n; ++neighbor) {
            if (adj[center][neighbor]) {
                if (link_degree[center][neighbor] != 2) return -1;
                if (start < 0) start = neighbor;
                ++incident_count;
            } else if (link_degree[center][neighbor] != 0) return -1;
        }
        bool seen[NMAX] = {}; int stack[NMAX], top = 0, reached = 0;
        seen[start] = true; stack[top++] = start;
        while (top) {
            int neighbor = stack[--top]; ++reached;
            for (int other = 0; other < n; ++other)
                if (link_adj[center][neighbor][other] && !seen[other]) {
                    seen[other] = true; stack[top++] = other;
                }
        }
        if (reached != incident_count) return -1;
    }
    for (int g = 0; g < f; ++g) for (int i = 0; i < width[g]; ++i) {
        int u = face[g][i], v = face[g][(i + 1) % width[g]], lo = u < v ? u : v, hi = u < v ? v : u, e = -1;
        for (int j = 0; j < m; ++j) if (eu[j] == lo && ev[j] == hi) { e = j; break; }
        if (e < 0 || count_face[e] >= 2) return -1;
        if (count_face[e]++ == 0) fa[e] = g; else fb[e] = g;
    }
    for (int e = 0; e < m; ++e) if (count_face[e] != 2 || fa[e] == fb[e]) return -1;
    if (!output || capacity < 8) return -2;

    int base = n + f, source = base, sink = base + 1, nodes = base + 2, ec = 0;
    Edge edges[EMAX];
    std::int64_t balance[NMAX + FMAX] = {};
    for (int v = 0; v < n; ++v) balance[v] = 4;
    for (int g = 0; g < f; ++g) {
        int d = width[g];
        balance[n+g] -= 2*d + (g == outside ? 4 : -4);
        for (int i = 0; i < d; ++i) {
            int v = face[g][i]; --balance[v]; ++balance[n+g];
            if (!add(edges, ec, v, n+g, 4*n, 0)) return -1;
        }
    }
    for (int e = 0; e < m; ++e)
        if (!add(edges, ec, n+fa[e], n+fb[e], 4*n, 1) || !add(edges, ec, n+fb[e], n+fa[e], 4*n, 1)) return -1;
    std::int64_t need = 0;
    for (int v = 0; v < base; ++v) {
        if (balance[v] > 0) { if (!add(edges, ec, source, v, balance[v], 0)) return -1; need += balance[v]; }
        else if (balance[v] < 0 && !add(edges, ec, v, sink, -balance[v], 0)) return -1;
    }
    std::int64_t pot[VMAX] = {}, flow = 0, cost = 0;
    while (flow < need) {
        std::int64_t dist[VMAX]; int parent[VMAX], used[VMAX] = {};
        for (int v = 0; v < nodes; ++v) { dist[v] = INF; parent[v] = -1; }
        dist[source] = 0;
        for (int step = 0; step < nodes; ++step) {
            int u = -1;
            for (int v = 0; v < nodes; ++v) if (!used[v] && dist[v] != INF && (u < 0 || dist[v] < dist[u])) u = v;
            if (u < 0) break;
            used[u] = 1;
            for (int e = 0; e < ec; ++e) if (edges[e].from == u && edges[e].cap > 0) {
                int v = edges[e].to; auto alt = dist[u] + edges[e].cost + pot[u] - pot[v];
                if (!used[v] && alt < dist[v]) { dist[v] = alt; parent[v] = e; }
            }
        }
        if (dist[sink] == INF) return -1;
        for (int v = 0; v < nodes; ++v) if (dist[v] != INF) pot[v] += dist[v];
        std::int64_t amount = need - flow, path_cost = 0;
        for (int v = sink; v != source; v = edges[parent[v]].from) {
            if (parent[v] < 0) return -1;
            if (amount > edges[parent[v]].cap) amount = edges[parent[v]].cap;
            path_cost += edges[parent[v]].cost;
        }
        for (int v = sink; v != source; v = edges[parent[v]].from) {
            int e = parent[v]; edges[e].cap -= amount; edges[edges[e].reverse].cap += amount;
        }
        flow += amount; cost += amount * path_cost;
    }
    auto bits = std::uint64_t(cost);
    for (std::size_t i = 0; i < 8; ++i) output[i] = std::uint8_t(bits >> (8*i));
    return 8;
}
