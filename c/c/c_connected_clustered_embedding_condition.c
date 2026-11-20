#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_M = 18, MAX_F = 12, MAX_INPUT = 55 };

typedef struct {
    int n, c, m, f, outer_u, outer_v, outer_face;
    int degree[MAX_N], rotation[MAX_N][MAX_N], mask[MAX_N];
    int edge_u[MAX_M], edge_v[MAX_M], face_of[MAX_N][MAX_N];
    uint8_t adjacent[MAX_N][MAX_N];
} ClusterGraph;

static int root(int parent[MAX_F], int x) {
    while (parent[x] != x) {
        parent[x] = parent[parent[x]];
        x = parent[x];
    }
    return x;
}

static int connected(const ClusterGraph *g, int mask) {
    int start = -1, expected = 0;
    for (int v = 0; v < g->n; ++v) if ((mask >> v) & 1) {
        if (start < 0) start = v;
        ++expected;
    }
    if (expected <= 1) return 1;
    uint8_t seen[MAX_N] = {0};
    int queue[MAX_N], head = 0, tail = 0;
    seen[start] = 1; queue[tail++] = start;
    while (head < tail) {
        const int u = queue[head++];
        for (int v = 0; v < g->n; ++v)
            if (((mask >> v) & 1) && g->adjacent[u][v] && !seen[v]) {
                seen[v] = 1; queue[tail++] = v;
            }
    }
    return tail == expected;
}

static int parse(const int64_t *input, size_t length, ClusterGraph *g) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return 0;
    const int64_t n64 = input[0], c64 = input[1];
    if (n64 < 3 || n64 > MAX_N || c64 < 0 || c64 > n64 - 2) return 0;
    g->n = (int)n64; g->c = (int)c64;
    if (input[2] < 0 || input[2] >= n64 || input[3] < 0 || input[3] >= n64 || input[2] == input[3]) return 0;
    g->outer_u = (int)input[2]; g->outer_v = (int)input[3];
    size_t offset = 4;
    int degree_sum = 0;
    for (int u = 0; u < g->n; ++u) {
        if (offset >= length) return 0;
        const int64_t d64 = input[offset++];
        if (d64 < 1 || d64 >= n64 || offset + (size_t)d64 > length) return 0;
        const int d = (int)d64;
        g->degree[u] = d; degree_sum += d;
        uint8_t row_seen[MAX_N] = {0};
        for (int i = 0; i < d; ++i) {
            const int64_t v64 = input[offset++];
            if (v64 < 0 || v64 >= n64 || v64 == u || row_seen[v64]) return 0;
            const int v = (int)v64;
            row_seen[v] = 1; g->rotation[u][i] = v; g->adjacent[u][v] = 1;
        }
    }
    if (degree_sum % 2 || offset + (size_t)g->c != length) return 0;
    g->m = degree_sum / 2;
    if (g->m < g->n - 1 || g->m > MAX_M) return 0;
    int edge_count = 0;
    int edge_id[MAX_N][MAX_N];
    for (int u = 0; u < MAX_N; ++u)
        for (int v = 0; v < MAX_N; ++v) edge_id[u][v] = -1;
    for (int u = 0; u < g->n; ++u) for (int v = 0; v < g->n; ++v) {
        if (g->adjacent[u][v] != g->adjacent[v][u]) return 0;
        if (u < v && g->adjacent[u][v]) {
            g->edge_u[edge_count] = u; g->edge_v[edge_count] = v;
            edge_id[u][v] = edge_id[v][u] = edge_count++;
        }
    }
    if (edge_count != g->m || !g->adjacent[g->outer_u][g->outer_v]) return 0;
    int all = (1 << g->n) - 1;
    for (int i = 0; i < g->c; ++i) {
        const int64_t raw = input[offset++];
        if (raw <= 0 || raw >= all) return 0;
        const int mask = (int)raw;
        int bits = 0;
        for (int v = 0; v < g->n; ++v) bits += (mask >> v) & 1;
        if (bits < 2) return 0;
        for (int j = 0; j < i; ++j) {
            if (g->mask[j] == mask) return 0;
            const int overlap = g->mask[j] & mask;
            if (overlap && overlap != g->mask[j] && overlap != mask) return 0;
        }
        g->mask[i] = mask;
        if (!connected(g, mask)) return 0;
    }
    if (!connected(g, all)) return 0;

    for (int u = 0; u < MAX_N; ++u)
        for (int v = 0; v < MAX_N; ++v) g->face_of[u][v] = -1;
    g->f = 0;
    for (int e = 0; e < g->m; ++e) {
        const int ends[2][2] = {{g->edge_u[e], g->edge_v[e]}, {g->edge_v[e], g->edge_u[e]}};
        for (int side = 0; side < 2; ++side) {
            const int start_u = ends[side][0], start_v = ends[side][1];
            if (g->face_of[start_u][start_v] >= 0) continue;
            if (g->f >= MAX_F) return 0;
            uint8_t local[MAX_N][MAX_N] = {{0}};
            int u = start_u, v = start_v, steps = 0;
            for (;;) {
                if (local[u][v] || g->face_of[u][v] >= 0) return 0;
                local[u][v] = 1;
                g->face_of[u][v] = g->f;
                int at = -1;
                for (int i = 0; i < g->degree[v]; ++i)
                    if (g->rotation[v][i] == u) { at = i; break; }
                if (at < 0) return 0;
                const int next = g->rotation[v][(at + 1) % g->degree[v]];
                u = v; v = next;
                if (u == start_u && v == start_v) break;
                if (++steps > 2 * g->m) return 0;
            }
            ++g->f;
        }
    }
    if (g->f != g->m - g->n + 2) return 0;
    for (int u = 0; u < g->n; ++u) for (int v = 0; v < g->n; ++v)
        if (g->adjacent[u][v] && g->face_of[u][v] < 0) return 0;
    g->outer_face = g->face_of[g->outer_u][g->outer_v];
    return g->outer_face >= 0;
}

int64_t c_connected_clustered_embedding_condition(const int64_t *input, size_t length) {
    ClusterGraph g = {0};
    if (!parse(input, length, &g)) return -1;
    for (int ci = 0; ci < g.c; ++ci) {
        const int mask = g.mask[ci];
        int parent[MAX_F];
        for (int f = 0; f < g.f; ++f) parent[f] = f;
        for (int e = 0; e < g.m; ++e) {
            const int u = g.edge_u[e], v = g.edge_v[e];
            if (((mask >> u) & 1) && ((mask >> v) & 1)) continue;
            int a = root(parent, g.face_of[u][v]);
            int b = root(parent, g.face_of[v][u]);
            parent[a] = b;
        }
        const int outside = root(parent, g.outer_face);
        for (int v = 0; v < g.n; ++v) if (!((mask >> v) & 1)) {
            int incident = 0;
            for (int u = 0; u < g.n; ++u) if (g.adjacent[v][u]) {
                incident = 1;
                if (root(parent, g.face_of[v][u]) != outside) return 0;
            }
            if (!incident) return -1;
        }
        for (int e = 0; e < g.m; ++e) {
            const int u = g.edge_u[e], v = g.edge_v[e];
            if (((mask >> u) & 1) && ((mask >> v) & 1)) continue;
            if (root(parent, g.face_of[u][v]) != outside) return 0;
        }
    }
    return 1;
}
