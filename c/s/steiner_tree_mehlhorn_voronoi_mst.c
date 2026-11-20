#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_M 14
#define MAX_INPUT 54
#define MAX_OUTPUT 72
#define INF INT64_C(0x3fffffffffffffff)

typedef struct { int u, v, weight; } Edge;
typedef struct { int a, b, left, right, edge; int64_t weight; } Candidate;

static int find_root(int parent[MAX_N], int x) {
    while (parent[x] != x) {
        parent[x] = parent[parent[x]];
        x = parent[x];
    }
    return x;
}

static int join(int parent[MAX_N], int rank[MAX_N], int a, int b) {
    int ra = find_root(parent, a), rb = find_root(parent, b);
    if (ra == rb) return 0;
    if (rank[ra] < rank[rb]) { int t = ra; ra = rb; rb = t; }
    parent[rb] = ra;
    if (rank[ra] == rank[rb]) rank[ra]++;
    return 1;
}

static int candidate_before(Candidate a, Candidate b) {
    if (a.weight != b.weight) return a.weight < b.weight;
    if (a.a != b.a) return a.a < b.a;
    if (a.b != b.b) return a.b < b.b;
    if (a.left != b.left) return a.left < b.left;
    if (a.right != b.right) return a.right < b.right;
    return a.edge < b.edge;
}

static int edge_before(const Edge edges[MAX_M], int a, int b) {
    if (edges[a].weight != edges[b].weight) return edges[a].weight < edges[b].weight;
    return a < b;
}

static int parse(const int64_t *input, size_t length, int *n, int *m, int *k,
                 int terminals[MAX_N], Edge edges[MAX_M]) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return 0;
    int64_t n0 = input[0], m0 = input[1], k0 = input[2];
    if (n0 < 2 || n0 > MAX_N || m0 < 1 || m0 > MAX_M || k0 < 2 || k0 > n0) return 0;
    *n = (int)n0; *m = (int)m0; *k = (int)k0;
    if (length < (size_t)(3 + *k + 3 * *m)) return 0;
    int is_terminal[MAX_N] = {0};
    size_t at = 3;
    for (int i = 0; i < *k; ++i) {
        int64_t t = input[at++];
        if (t < 0 || t >= *n || is_terminal[t]) return 0;
        terminals[i] = (int)t;
        is_terminal[t] = 1;
    }
    unsigned int seen[MAX_N] = {0};
    for (int e = 0; e < *m; ++e) {
        int64_t u = input[at++], v = input[at++], w = input[at++];
        if (u < 0 || u >= v || v >= *n || w < 1 || w > 9) return 0;
        if ((seen[u] & (1U << v)) != 0) return 0;
        seen[u] |= 1U << v;
        edges[e] = (Edge){(int)u, (int)v, (int)w};
    }
    if (at != length) return 0;
    int reached[MAX_N] = {0}, queue[MAX_N], head = 0, tail = 0;
    reached[0] = 1; queue[tail++] = 0;
    while (head < tail) {
        int u = queue[head++];
        for (int e = 0; e < *m; ++e) {
            int v = edges[e].u == u ? edges[e].v : (edges[e].v == u ? edges[e].u : -1);
            if (v >= 0 && !reached[v]) { reached[v] = 1; queue[tail++] = v; }
        }
    }
    for (int v = 0; v < *n; ++v) if (!reached[v]) return 0;
    return 1;
}

static int solve(int n, int m, int k, const int terminals[MAX_N], const Edge edges[MAX_M],
                 int64_t *cost_out, int result_edges[MAX_M], int *result_count) {
    int64_t dist[MAX_N];
    int owner[MAX_N], pred[MAX_N], pred_edge[MAX_N], settled[MAX_N] = {0};
    for (int v = 0; v < n; ++v) { dist[v] = INF; owner[v] = n; pred[v] = -1; pred_edge[v] = -1; }
    for (int i = 0; i < k; ++i) { dist[terminals[i]] = 0; owner[terminals[i]] = terminals[i]; }
    for (int iter = 0; iter < n; ++iter) {
        int u = -1;
        for (int v = 0; v < n; ++v)
            if (!settled[v] && (u < 0 || dist[v] < dist[u] ||
                (dist[v] == dist[u] && (owner[v] < owner[u] || (owner[v] == owner[u] && v < u))))) u = v;
        if (u < 0 || dist[u] == INF) break;
        settled[u] = 1;
        for (int e = 0; e < m; ++e) {
            int v = edges[e].u == u ? edges[e].v : (edges[e].v == u ? edges[e].u : -1);
            if (v < 0) continue;
            int64_t nd = dist[u] + edges[e].weight;
            if (nd < dist[v] || (nd == dist[v] && owner[u] < owner[v])) {
                dist[v] = nd; owner[v] = owner[u]; pred[v] = u; pred_edge[v] = e;
            } else if (nd == dist[v] && owner[u] == owner[v] && !settled[v] &&
                       (pred[v] < 0 || u < pred[v] || (u == pred[v] && e < pred_edge[v]))) {
                pred[v] = u; pred_edge[v] = e;
            }
        }
    }
    for (int v = 0; v < n; ++v) if (dist[v] == INF || owner[v] == n) return 0;

    Candidate best[MAX_N][MAX_N];
    int has[MAX_N][MAX_N] = {{0}};
    for (int e = 0; e < m; ++e) {
        int u = edges[e].u, v = edges[e].v;
        int a = owner[u], b = owner[v];
        if (a == b) continue;
        int left = u, right = v;
        if (a > b) { int t = a; a = b; b = t; left = v; right = u; }
        Candidate c = {a, b, left, right, e, dist[u] + edges[e].weight + dist[v]};
        Candidate old = best[a][b];
        if (!has[a][b] || c.weight < old.weight ||
            (c.weight == old.weight && (c.left < old.left ||
             (c.left == old.left && (c.right < old.right ||
              (c.right == old.right && c.edge < old.edge)))))) {
            best[a][b] = c; has[a][b] = 1;
        }
    }
    Candidate candidates[MAX_M]; int cn = 0;
    for (int a = 0; a < n; ++a) for (int b = a + 1; b < n; ++b)
        if (has[a][b]) candidates[cn++] = best[a][b];
    for (int i = 1; i < cn; ++i) {
        Candidate x = candidates[i]; int j = i;
        while (j > 0 && candidate_before(x, candidates[j - 1])) { candidates[j] = candidates[j - 1]; --j; }
        candidates[j] = x;
    }
    int parent[MAX_N], rank[MAX_N] = {0}, chosen[MAX_N], chosen_count = 0;
    for (int v = 0; v < n; ++v) parent[v] = v;
    for (int i = 0; i < cn && chosen_count < k - 1; ++i)
        if (join(parent, rank, candidates[i].a, candidates[i].b)) chosen[chosen_count++] = i;
    if (chosen_count != k - 1) return 0;

    int used[MAX_M] = {0};
    for (int i = 0; i < chosen_count; ++i) {
        Candidate c = candidates[chosen[i]];
        used[c.edge] = 1;
        int x = c.left;
        while (x != c.a) { if (pred_edge[x] < 0) return 0; used[pred_edge[x]] = 1; x = pred[x]; }
        x = c.right;
        while (x != c.b) { if (pred_edge[x] < 0) return 0; used[pred_edge[x]] = 1; x = pred[x]; }
    }

    int order[MAX_M], on = 0;
    for (int e = 0; e < m; ++e) if (used[e]) order[on++] = e;
    for (int i = 1; i < on; ++i) {
        int x = order[i], j = i;
        while (j > 0 && edge_before(edges, x, order[j - 1])) { order[j] = order[j - 1]; --j; }
        order[j] = x;
    }
    for (int v = 0; v < n; ++v) parent[v] = v;
    for (int v = 0; v < n; ++v) rank[v] = 0;
    int tree[MAX_M] = {0};
    for (int i = 0; i < on; ++i) { int e = order[i]; if (join(parent, rank, edges[e].u, edges[e].v)) tree[e] = 1; }
    int root = find_root(parent, terminals[0]);
    for (int i = 1; i < k; ++i) if (find_root(parent, terminals[i]) != root) return 0;

    int terminal_flag[MAX_N] = {0}, degree[MAX_N] = {0}, incident[MAX_N][MAX_M] = {{0}};
    for (int i = 0; i < k; ++i) terminal_flag[terminals[i]] = 1;
    for (int e = 0; e < m; ++e) if (tree[e]) { degree[edges[e].u]++; degree[edges[e].v]++; incident[edges[e].u][e] = 1; incident[edges[e].v][e] = 1; }
    int queue[2 * MAX_N], queued[MAX_N] = {0}, head = 0, tail = 0;
    for (int v = 0; v < n; ++v) if (!terminal_flag[v] && degree[v] <= 1) { queue[tail++] = v; queued[v] = 1; }
    while (head < tail) {
        int u = queue[head++];
        if (degree[u] > 1) continue;
        for (int e = 0; e < m; ++e) if (tree[e] && incident[u][e]) {
            tree[e] = 0;
            int v = edges[e].u == u ? edges[e].v : edges[e].u;
            degree[u]--; degree[v]--;
            if (!terminal_flag[v] && degree[v] <= 1 && !queued[v]) { queue[tail++] = v; queued[v] = 1; }
        }
    }
    int count = 0; int64_t cost = 0;
    for (int e = 0; e < m; ++e) if (tree[e]) { result_edges[count++] = e; cost += edges[e].weight; }
    if (count <= 0 || count > n - 1) return 0;
    *cost_out = cost; *result_count = count;
    return 1;
}

static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (int i = 0; i < 8; ++i) { out[at + (size_t)i] = (uint8_t)(bits & 255U); bits >>= 8; }
}

int64_t steiner_tree_mehlhorn_voronoi_mst(const int64_t *input, size_t length,
                                          uint8_t *output, size_t capacity) {
    int n, m, k, terminals[MAX_N], result_edges[MAX_M], result_count;
    Edge edges[MAX_M]; int64_t cost;
    if (!parse(input, length, &n, &m, &k, terminals, edges)) return -1;
    if (!solve(n, m, k, terminals, edges, &cost, result_edges, &result_count)) return -1;
    size_t bytes = (size_t)(2 + result_count) * 8;
    if (output == NULL || capacity < bytes || bytes > MAX_OUTPUT) return -2;
    put_i64(output, 0, cost); put_i64(output, 8, result_count);
    for (int i = 0; i < result_count; ++i) put_i64(output, 16 + (size_t)i * 8, result_edges[i]);
    return (int64_t)bytes;
}
