#include <stddef.h>
#include <stdint.h>

#define N 4
#define C 4
#define CE 3
#define ALL_E 6

typedef struct { int u, v, w; } Edge;

static int find(int p[N], int x) {
    while (p[x] != x) { p[x] = p[p[x]]; x = p[x]; }
    return x;
}
static int join(int p[N], int a, int b) {
    a = find(p, a); b = find(p, b);
    if (a == b) return 0;
    p[b] = a; return 1;
}
static void put_i64(uint8_t *out, size_t word, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[word * 8 + b] = (uint8_t)(bits >> (8 * b));
}
static int terminals_connected(const int h[N][N], int mask) {
    int p[N]; for (int i = 0; i < N; ++i) p[i] = i;
    for (int i = 0; i < N; ++i) for (int j = i + 1; j < N; ++j)
        if (h[i][j]) join(p, i, j);
    int root = -1;
    for (int i = 0; i < N; ++i) if (mask & (1 << i)) {
        if (root < 0) root = find(p, i);
        else if (find(p, i) != root) return 0;
    }
    return 1;
}
static int terminal_groups(const int h[N][N], int mask, int roots[N], int *groups) {
    int p[N]; for (int i = 0; i < N; ++i) p[i] = i;
    for (int i = 0; i < N; ++i) for (int j = i + 1; j < N; ++j)
        if (h[i][j]) join(p, i, j);
    int count = 0;
    for (int i = 0; i < N; ++i) roots[i] = -1;
    for (int i = 0; i < N; ++i) if (mask & (1 << i)) {
        int r = find(p, i), id = 0;
        while (id < count && groups[id] != r) ++id;
        if (id == count) groups[count++] = r;
        roots[i] = id;
    }
    return count;
}
static int mst_metric(const int w[N][N], int mask) {
    Edge e[ALL_E]; int n = 0;
    for (int i = 0; i < N; ++i) if (mask & (1 << i))
        for (int j = i + 1; j < N; ++j) if (mask & (1 << j))
            e[n++] = Edge{i, j, w[i][j]};
    for (int i = 1; i < n; ++i) {
        Edge x = e[i]; int j = i;
        while (j && (e[j-1].w > x.w || (e[j-1].w == x.w &&
               (e[j-1].u > x.u || (e[j-1].u == x.u && e[j-1].v > x.v))))) {
            e[j] = e[j-1]; --j;
        }
        e[j] = x;
    }
    int p[N]; for (int i = 0; i < N; ++i) p[i] = i;
    int cost = 0, used = 0;
    for (int i = 0; i < n; ++i) if (join(p, e[i].u, e[i].v)) { cost += e[i].w; ++used; }
    return used > 0 ? cost : 0;
}
static int mst_forest(const int w[N][N], const int h[N][N], Edge chosen[N-1], int *chosen_count) {
    Edge e[ALL_E]; int n = 0;
    for (int i = 0; i < N; ++i) for (int j = i + 1; j < N; ++j)
        if (h[i][j]) e[n++] = Edge{i, j, w[i][j]};
    for (int i = 1; i < n; ++i) {
        Edge x = e[i]; int j = i;
        while (j && (e[j-1].w > x.w || (e[j-1].w == x.w &&
               (e[j-1].u > x.u || (e[j-1].u == x.u && e[j-1].v > x.v))))) {
            e[j] = e[j-1]; --j;
        }
        e[j] = x;
    }
    int p[N]; for (int i = 0; i < N; ++i) p[i] = i;
    int cost = 0, used = 0;
    for (int i = 0; i < n; ++i) if (join(p, e[i].u, e[i].v)) {
        chosen[used++] = e[i]; cost += e[i].w;
    }
    *chosen_count = used;
    return cost;
}
static int mst_after_contract(const int w[N][N], const int h[N][N], int mask) {
    int d[N][N], parent[N], roots[N], group_roots[N], g = 0;
    for (int i = 0; i < N; ++i) {
        parent[i] = i;
        for (int j = 0; j < N; ++j) d[i][j] = w[i][j];
    }
    for (int i = 0; i < N; ++i) for (int j = i + 1; j < N; ++j) if (h[i][j]) {
        d[i][j] = d[j][i] = 0; join(parent, i, j);
    }
    for (int k = 0; k < N; ++k) for (int i = 0; i < N; ++i) for (int j = 0; j < N; ++j)
        if (d[i][j] > d[i][k] + d[k][j]) d[i][j] = d[i][k] + d[k][j];
    for (int i = 0; i < N; ++i) roots[i] = -1;
    for (int i = 0; i < N; ++i) if (mask & (1 << i)) {
        int r = find(parent, i), x = 0;
        while (x < g && group_roots[x] != r) ++x;
        if (x == g) group_roots[g++] = r;
        roots[i] = x;
    }
    if (g <= 1) return 0;
    Edge e[ALL_E]; int ec = 0;
    for (int a = 0; a < g; ++a) for (int b = a + 1; b < g; ++b) {
        int best = 1000000;
        for (int i = 0; i < N; ++i) if (find(parent, i) == group_roots[a])
            for (int j = 0; j < N; ++j) if (find(parent, j) == group_roots[b] && d[i][j] < best) best = d[i][j];
        e[ec++] = Edge{a, b, best};
    }
    for (int i = 1; i < ec; ++i) {
        Edge x = e[i]; int j = i;
        while (j && (e[j-1].w > x.w || (e[j-1].w == x.w &&
               (e[j-1].u > x.u || (e[j-1].u == x.u && e[j-1].v > x.v))))) {
            e[j] = e[j-1]; --j;
        }
        e[j] = x;
    }
    int p[N]; for (int i = 0; i < N; ++i) p[i] = i;
    int cost = 0;
    for (int i = 0; i < ec; ++i) if (join(p, e[i].u, e[i].v)) cost += e[i].w;
    return cost;
}

extern "C" int64_t steiner_tree_gain_greedy(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (!input || length < 4 || length > 37) return -1;
    int n = (int)input[0]; int64_t mask0 = input[1], count0 = input[2];
    if (n < 2 || n > N || mask0 <= 0 || (mask0 >> n) != 0 || count0 < 1 || count0 > C) return -1;
    int mask = (int)mask0, count = (int)count0, terminal_count = 0;
    for (int i = 0; i < n; ++i) if (mask & (1 << i)) ++terminal_count;
    if (terminal_count < 2) return -1;
    int w[N][N] = {{0}}; size_t at = 3;
    for (int i = 0; i < n; ++i) for (int j = i + 1; j < n; ++j) {
        if (at >= length || input[at] < 0 || input[at] > 1000) return -1;
        w[i][j] = w[j][i] = (int)input[at++];
    }
    for (int i = 0; i < n; ++i) for (int j = 0; j < n; ++j) for (int k = 0; k < n; ++k)
        if (w[i][j] > w[i][k] + w[k][j]) return -1;
    int cu[C][CE] = {{0}}, cv[C][CE] = {{0}}, ce[C] = {0};
    int family[N][N] = {{0}};
    for (int c = 0; c < count; ++c) {
        if (at >= length) return -1;
        int64_t ec0 = input[at++];
        if (ec0 < 1 || ec0 > n - 1 || at + 2 * (size_t)ec0 > length) return -1;
        ce[c] = (int)ec0;
        int p[N], degree[N] = {0}; for (int i = 0; i < N; ++i) p[i] = i;
        for (int e = 0; e < ce[c]; ++e) {
            int64_t u0 = input[at++], v0 = input[at++];
            if (u0 < 0 || u0 >= n || v0 < 0 || v0 >= n || u0 == v0) return -1;
            int u = (int)u0, v = (int)v0;
            if (!join(p, u, v)) return -1;
            for (int x = 0; x < e; ++x) if ((cu[c][x] == u && cv[c][x] == v) || (cu[c][x] == v && cv[c][x] == u)) return -1;
            cu[c][e] = u; cv[c][e] = v; ++degree[u]; ++degree[v]; family[u][v] = family[v][u] = 1;
        }
        int leaves = 0, root = -1, seen = 0;
        for (int i = 0; i < n; ++i) if (degree[i]) {
            ++seen;
            if (root < 0) root = find(p, i);
            else if (find(p, i) != root) return -1;
            if (degree[i] == 1) { if (!(mask & (1 << i))) return -1; ++leaves; }
            else if (mask & (1 << i)) return -1;
        }
        if (seen != ce[c] + 1 || leaves < 2 || leaves > 3) return -1;
        for (int i = 0; i < n; ++i) if (degree[i] > 0 && degree[i] != 1 && degree[i] < 2) return -1;
    }
    if (at != length) return -1;
    int family_p[N]; for (int i = 0; i < N; ++i) family_p[i] = i;
    for (int i = 0; i < n; ++i) for (int j = i + 1; j < n; ++j) if (family[i][j]) join(family_p, i, j);
    int first = -1;
    for (int i = 0; i < n; ++i) if (mask & (1 << i)) {
        if (first < 0) first = find(family_p, i);
        else if (find(family_p, i) != first) return -1;
    }

    int h[N][N] = {{0}}, selected[C] = {0};
    int baseline = mst_metric(w, mask), iterations = 0;
    while (!terminals_connected(h, mask)) {
        int roots[N], groups[N], before = terminal_groups(h, mask, roots, groups);
        int best = -1, best_gain = -1000000000;
        for (int c = 0; c < count; ++c) if (!selected[c]) {
            int trial[N][N]; for (int i = 0; i < N; ++i) for (int j = 0; j < N; ++j) trial[i][j] = h[i][j];
            for (int e = 0; e < ce[c]; ++e) trial[cu[c][e]][cv[c][e]] = trial[cv[c][e]][cu[c][e]] = 1;
            int r2[N], g2[N]; int after = terminal_groups(trial, mask, r2, g2);
            if (after >= before) continue;
            Edge unused[N-1]; int unused_count = 0;
            int gain = baseline - mst_after_contract(w, trial, mask) - mst_forest(w, trial, unused, &unused_count);
            if (best < 0 || gain > best_gain) { best = c; best_gain = gain; }
        }
        if (best < 0 || ++iterations > count) return -1;
        selected[best] = 1;
        for (int e = 0; e < ce[best]; ++e) h[cu[best][e]][cv[best][e]] = h[cv[best][e]][cu[best][e]] = 1;
    }
    Edge tree[N-1]; int edge_count = 0;
    int cost = mst_forest(w, h, tree, &edge_count);
    if (output == NULL || capacity < 8u * (size_t)(3 + 2 * edge_count)) return -2;
    put_i64(output, 0, 1); put_i64(output, 1, cost); put_i64(output, 2, edge_count);
    for (int i = 0; i < edge_count; ++i) { put_i64(output, 3 + 2 * i, tree[i].u); put_i64(output, 4 + 2 * i, tree[i].v); }
    return (int64_t)(8u * (size_t)(3 + 2 * edge_count));
}
