/* Clean-room bounded DOI 580 greedy hierarchical hub labeling profile. */
#include <stddef.h>
#include <stdint.h>

#define N 8
#define MAX_M 28
#define MAX_OUT (1 + 2 * N + N * N)

static void put_i64(uint8_t *out, size_t pos, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[pos + b] = (uint8_t)(bits >> (8 * b));
}
static int ancestor(int parent[N][N], int source, int a, int target) {
    int v = target;
    while (v >= 0) { if (v == a) return 1; if (v == source) break; v = parent[source][v]; }
    return 0;
}

int64_t hub_labeling_greedy_order(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 2 + 2 * MAX_M) return -1;
    int64_t n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > N || m0 < 0 || m0 > n0 * (n0 - 1) / 2 || length != 2 + 2 * (size_t)m0) return -1;
    int n = (int)n0, m = (int)m0;
    uint8_t adj[N][N] = {{0}};
    int64_t prev_u = -1, prev_v = -1;
    for (int e = 0; e < m; ++e) {
        int64_t u = input[2 + 2 * e], v = input[3 + 2 * e];
        if (u < 0 || v <= u || v >= n || (e && (u < prev_u || (u == prev_u && v <= prev_v)))) return -1;
        adj[u][v] = adj[v][u] = 1; prev_u = u; prev_v = v;
    }
    int parent[N][N], depth[N][N], ways[N][N];
    for (int s = 0; s < n; ++s) {
        for (int v = 0; v < n; ++v) { parent[s][v] = -1; depth[s][v] = -1; ways[s][v] = 0; }
        int queue[N], head = 0, tail = 0;
        queue[tail++] = s; depth[s][s] = 0; ways[s][s] = 1;
        while (head < tail) {
            int u = queue[head++];
            for (int v = 0; v < n; ++v) if (adj[u][v]) {
                if (depth[s][v] < 0) { depth[s][v] = depth[s][u] + 1; parent[s][v] = u; ways[s][v] = ways[s][u]; queue[tail++] = v; }
                else if (depth[s][v] == depth[s][u] + 1) { ways[s][v] += ways[s][u]; if (ways[s][v] > 2) ways[s][v] = 2; }
            }
        }
        for (int v = 0; v < n; ++v) if (depth[s][v] < 0 || ways[s][v] != 1) return -1;
    }
    uint8_t active[N][N];
    for (int s = 0; s < n; ++s) for (int t = 0; t < n; ++t) active[s][t] = 1;
    int order[N], rank[N];
    for (int turn = 0; turn < n; ++turn) {
        int count[N] = {0};
        for (int s = 0; s < n; ++s) for (int t = 0; t < n; ++t) if (active[s][t]) {
            int v = t;
            while (v >= 0) { ++count[v]; if (v == s) break; v = parent[s][v]; }
        }
        int best = 0;
        for (int v = 1; v < n; ++v) if (count[v] > count[best]) best = v;
        order[turn] = best; rank[best] = turn;
        for (int s = 0; s < n; ++s) for (int t = 0; t < n; ++t)
            if (active[s][t] && ancestor(parent, s, best, t)) active[s][t] = 0;
    }
    uint8_t has[N][N] = {{0}};
    int label_dist[N][N] = {{0}};
    for (int u = 0; u < n; ++u) for (int v = u; v < n; ++v) {
        int path[N], length_path = 0, x = v;
        while (x >= 0) { path[length_path++] = x; if (x == u) break; x = parent[u][x]; }
        if (x < 0) return -1;
        int hub = path[0];
        for (int i = 1; i < length_path; ++i) if (rank[path[i]] < rank[hub]) hub = path[i];
        has[u][hub] = has[v][hub] = 1;
        label_dist[u][hub] = depth[u][hub]; label_dist[v][hub] = depth[v][hub];
    }
    int64_t staged[MAX_OUT]; size_t used = 0;
    staged[used++] = n;
    for (int i = 0; i < n; ++i) staged[used++] = order[i];
    for (int v = 0; v < n; ++v) {
        int count = 0; for (int h = 0; h < n; ++h) count += has[v][h] != 0;
        staged[used++] = count;
        for (int h = 0; h < n; ++h) if (has[v][h]) staged[used++] = h | (label_dist[v][h] << 8);
    }
    size_t required = used * 8;
    if (output == NULL || capacity < required) return -2;
    for (size_t i = 0; i < used; ++i) put_i64(output, i * 8, staged[i]);
    return (int64_t)required;
}
