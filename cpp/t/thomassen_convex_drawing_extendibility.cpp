#include <cstddef>
#include <cstdint>

namespace {
constexpr int N = 8, M = 18, F = 12, INPUT_MAX = 93;
constexpr int FLOW_NODES = 2 * N + 2, STATES = 1 << N;

bool connected(const bool adj[N][N], int n, int removed) {
    bool seen[N] = {};
    int stack[N], top = 0, count = 0;
    int start = removed == 0 ? 1 : 0;
    seen[start] = true; stack[top++] = start;
    while (top) {
        int u = stack[--top]; ++count;
        for (int v = 0; v < n; ++v)
            if (v != removed && adj[u][v] && !seen[v]) { seen[v] = true; stack[top++] = v; }
    }
    return count == n - (removed >= 0);
}

bool three_outer_paths(const bool adj[N][N], const bool outer[N], int n, int root) {
    int residual[FLOW_NODES][FLOW_NODES] = {};
    int source = 2 * n, sink = source + 1, nodes = sink + 1;
    for (int v = 0; v < n; ++v) if (v != root) residual[2*v][2*v+1] = 1;
    for (int u = 0; u < n; ++u) for (int v = u + 1; v < n; ++v) {
        if (!adj[u][v]) continue;
        if (u == root) ++residual[source][2*v];
        else if (v == root) ++residual[source][2*u];
        else { ++residual[2*u+1][2*v]; ++residual[2*v+1][2*u]; }
    }
    for (int v = 0; v < n; ++v) if (outer[v] && v != root) ++residual[2*v+1][sink];
    for (int flow = 0; flow < 3; ++flow) {
        int parent[FLOW_NODES], queue[FLOW_NODES], head = 0, tail = 0;
        for (int v = 0; v < nodes; ++v) parent[v] = -1;
        parent[source] = source; queue[tail++] = source;
        while (head < tail && parent[sink] < 0) {
            int u = queue[head++];
            for (int v = 0; v < nodes; ++v) if (residual[u][v] > 0 && parent[v] < 0) {
                parent[v] = u; queue[tail++] = v;
                if (v == sink) break;
            }
        }
        if (parent[sink] < 0) return false;
        for (int v = sink; v != source; v = parent[v]) {
            int u = parent[v]; --residual[u][v]; ++residual[v][u];
        }
    }
    return true;
}

bool condition_three(const bool inner[N][N], const int degree[N], int n) {
    int size[STATES] = {};
    for (int mask = 1; mask < (1 << n); ++mask) size[mask] = size[mask >> 1] + (mask & 1);
    for (int start = 0; start < n; ++start) {
        std::uint8_t dp[STATES][N];
        for (int mask = 0; mask < STATES; ++mask) for (int last = 0; last < N; ++last) dp[mask][last] = UINT8_MAX;
        dp[1 << start][start] = degree[start] >= 3;
        for (int mask = 0; mask < (1 << n); ++mask) {
            if (!(mask & (1 << start))) continue;
            for (int last = start; last < n; ++last) {
                auto used = dp[mask][last];
                if (used == UINT8_MAX) continue;
                if (size[mask] >= 3 && inner[last][start] && used < 3) return false;
                for (int next = start + 1; next < n; ++next) {
                    int bit = 1 << next;
                    if ((mask & bit) || !inner[last][next]) continue;
                    int candidate = used + (degree[next] >= 3), next_mask = mask | bit;
                    if (candidate < dp[next_mask][next]) dp[next_mask][next] = std::uint8_t(candidate);
                }
            }
        }
    }
    return true;
}
}

extern "C" std::int64_t thomassen_convex_drawing_extendibility(const std::int64_t *input,
                                                                 std::size_t length) {
    if (!input || length < 5 || length > INPUT_MAX) return -1;
    auto n0 = input[0], m0 = input[1], f0 = input[2], outer0 = input[3], sides0 = input[4];
    if (n0 < 3 || n0 > N || m0 < n0 || m0 > M || m0 > 3*n0-6 || f0 < 2 || f0 > F ||
        f0 != m0-n0+2 || outer0 < 0 || outer0 >= f0 || sides0 < 3 || sides0 > n0) return -1;
    int n = int(n0), m = int(m0), f = int(f0), outer_id = int(outer0), side_count = int(sides0);
    bool adj[N][N] = {};
    int eu[M], ev[M];
    for (int e = 0; e < m; ++e) {
        std::size_t p = 5 + std::size_t(2*e);
        if (p + 1 >= length) return -1;
        auto u0 = input[p], v0 = input[p+1];
        if (u0 < 0 || u0 >= v0 || v0 >= n) return -1;
        int u = int(u0), v = int(v0);
        if (adj[u][v] || (e && (u < eu[e-1] || (u == eu[e-1] && v <= ev[e-1])))) return -1;
        adj[u][v] = adj[v][u] = true; eu[e] = u; ev[e] = v;
    }
    int face[F][N] = {}, width[F] = {}, darts[N][N] = {};
    std::size_t p = 5 + std::size_t(2*m);
    for (int g = 0; g < f; ++g) {
        if (p >= length) return -1;
        auto w0 = input[p++];
        if (w0 < 3 || w0 > n || p + std::size_t(w0) > length) return -1;
        width[g] = int(w0); bool row[N] = {};
        for (int i = 0; i < width[g]; ++i) {
            auto x0 = input[p++];
            if (x0 < 0 || x0 >= n || row[x0]) return -1;
            face[g][i] = int(x0); row[x0] = true;
        }
        for (int i = 0; i < width[g]; ++i) {
            int u = face[g][i], v = face[g][(i+1)%width[g]];
            if (!adj[u][v]) return -1;
            ++darts[u][v];
        }
    }
    if (p + std::size_t(side_count) != length) return -1;
    int apex[N];
    for (int i = 0; i < side_count; ++i) {
        auto position = input[p++];
        if (position < 0 || position >= width[outer_id] || (i && position <= apex[i-1])) return -1;
        apex[i] = int(position);
    }
    for (int e = 0; e < m; ++e) if (darts[eu[e]][ev[e]] != 1 || darts[ev[e]][eu[e]] != 1) return -1;
    if (!connected(adj, n, -1)) return -1;
    for (int v = 0; v < n; ++v) if (!connected(adj, n, v)) return -1;

    bool link_adj[N][N][N] = {};
    int link_degree[N][N] = {};
    for (int g = 0; g < f; ++g) for (int i = 0; i < width[g]; ++i) {
        int center = face[g][i], before = face[g][(i+width[g]-1)%width[g]], after = face[g][(i+1)%width[g]];
        if (before == after) return -1;
        link_adj[center][before][after] = link_adj[center][after][before] = true;
        ++link_degree[center][before]; ++link_degree[center][after];
    }
    for (int center = 0; center < n; ++center) {
        int seed = -1, incident_count = 0;
        for (int v = 0; v < n; ++v) {
            if (adj[center][v]) { if (link_degree[center][v] != 2) return -1; if (seed < 0) seed = v; ++incident_count; }
            else if (link_degree[center][v]) return -1;
        }
        if (seed < 0) return -1;
        bool seen[N] = {}; int stack[N], top = 0, reached = 0;
        seen[seed] = true; stack[top++] = seed;
        while (top) { int v = stack[--top]; ++reached;
            for (int w = 0; w < n; ++w) if (link_adj[center][v][w] && !seen[w]) { seen[w] = true; stack[top++] = w; }
        }
        if (reached != incident_count) return -1;
    }

    bool outer_v[N] = {}, outer_e[N][N] = {};
    for (int i = 0; i < width[outer_id]; ++i) {
        int u = face[outer_id][i], v = face[outer_id][(i+1)%width[outer_id]];
        outer_v[u] = true; outer_e[u][v] = outer_e[v][u] = true;
    }
    int fa[M] = {}, fb[M] = {}, fc[M] = {};
    for (int g = 0; g < f; ++g) for (int i = 0; i < width[g]; ++i) {
        int u = face[g][i], v = face[g][(i+1)%width[g]], lo = u < v ? u : v, hi = u < v ? v : u, e = -1;
        for (int j = 0; j < m; ++j) if (eu[j] == lo && ev[j] == hi) { e = j; break; }
        if (e < 0 || fc[e] >= 2) return -1;
        if (fc[e]++ == 0) fa[e] = g; else fb[e] = g;
    }
    for (int e = 0; e < m; ++e) if (fc[e] != 2 || fa[e] == fb[e]) return -1;
    bool side[N][N] = {};
    for (int s = 0; s < side_count; ++s) {
        int at = apex[s], end = apex[(s+1)%side_count];
        for (;;) { side[s][face[outer_id][at]] = true; if (at == end) break; at = (at+1)%width[outer_id]; }
    }
    int degree[N] = {};
    for (int u = 0; u < n; ++u) for (int v = 0; v < n; ++v) degree[u] += adj[u][v];
    for (int root = 0; root < n; ++root)
        if (!outer_v[root] && degree[root] >= 3 && !three_outer_paths(adj, outer_v, n, root)) return 0;
    bool seen_inner[N] = {};
    for (int seed = 0; seed < n; ++seed) if (!outer_v[seed] && !seen_inner[seed]) {
        bool border[N] = {}; int stack[N], top = 0; seen_inner[seed] = true; stack[top++] = seed;
        while (top) { int u = stack[--top]; for (int v = 0; v < n; ++v) if (adj[u][v]) {
            if (outer_v[v]) border[v] = true; else if (!seen_inner[v]) { seen_inner[v] = true; stack[top++] = v; }
        }}
        for (int s = 0; s < side_count; ++s) { bool nonempty = false, contained = true;
            for (int v = 0; v < n; ++v) if (border[v]) { nonempty = true; if (!side[s][v]) contained = false; }
            if (nonempty && contained) return 0;
        }
    }
    for (int e = 0; e < m; ++e) if (!outer_e[eu[e]][ev[e]])
        for (int s = 0; s < side_count; ++s) if (side[s][eu[e]] && side[s][ev[e]]) return 0;
    bool inner[N][N] = {};
    for (int e = 0; e < m; ++e) if (!outer_e[eu[e]][ev[e]]) inner[eu[e]][ev[e]] = inner[ev[e]][eu[e]] = true;
    return condition_three(inner, degree, n) ? 1 : 0;
}
