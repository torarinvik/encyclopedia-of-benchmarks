#include <stddef.h>
#include <stdint.h>

#define MAX_N 6
#define MAX_M 10
#define MAX_DARTS (2 * MAX_M)
#define MAX_FACES (MAX_M - 2 + 2)
#define MAX_INPUT 61
#define MAX_AUGMENTATIONS 25
#define INF_DIST INT64_C(0x3fffffffffffffff)

typedef struct {
    int n, m, source, sink;
    int u[MAX_M], v[MAX_M], cap[MAX_M];
    int degree[MAX_N], rot[MAX_N][MAX_N];
    int local_pos[MAX_N][MAX_M];
    int left_face[MAX_DARTS], right_face[MAX_DARTS];
    int faces, infinity, root_anchor;
} PlanarFlow;

static int dart_tail(const PlanarFlow *g, int dart) {
    int e = dart / 2;
    return (dart & 1) ? g->v[e] : g->u[e];
}

static int dart_head(const PlanarFlow *g, int dart) {
    int e = dart / 2;
    return (dart & 1) ? g->u[e] : g->v[e];
}

static int next_left_dart(const PlanarFlow *g, int dart) {
    int vertex = dart_head(g, dart);
    int edge = dart / 2;
    int degree = g->degree[vertex];
    int position = g->local_pos[vertex][edge];
    if (degree <= 0 || position < 0) return -1;
    int next_edge = g->rot[vertex][(position + degree - 1) % degree];
    return 2 * next_edge + (g->v[next_edge] == vertex);
}

static int parse_graph(const int64_t *a, size_t length, PlanarFlow *g) {
    if (a == NULL || length < 4 || length > MAX_INPUT) return 0;
    int64_t n0 = a[0], m0 = a[1], s0 = a[2], t0 = a[3];
    if (n0 < 2 || n0 > MAX_N || m0 < 1 || m0 > MAX_M ||
        s0 < 0 || s0 >= n0 || t0 < 0 || t0 >= n0 || s0 == t0) return 0;
    g->n = (int)n0; g->m = (int)m0;
    g->source = (int)s0; g->sink = (int)t0;
    if (length < (size_t)(4 + 3 * g->m)) return 0;

    int pair_seen[MAX_N][MAX_N] = {{0}};
    size_t at = 4;
    for (int e = 0; e < g->m; ++e) {
        int64_t u = a[at++], v = a[at++], c = a[at++];
        if (u < 0 || u >= g->n || v < 0 || v >= g->n || u == v || c < 1 || c > 5)
            return 0;
        if (pair_seen[u][v] || pair_seen[v][u]) return 0;
        pair_seen[u][v] = pair_seen[v][u] = 1;
        g->u[e] = (int)u; g->v[e] = (int)v; g->cap[e] = (int)c;
    }

    int occurrence[MAX_M][2] = {{0}};
    int used[MAX_N][MAX_M] = {{0}};
    for (int x = 0; x < g->n; ++x)
        for (int e = 0; e < g->m; ++e) g->local_pos[x][e] = -1;
    for (int x = 0; x < g->n; ++x) {
        if (at >= length) return 0;
        int64_t d0 = a[at++];
        if (d0 < 1 || d0 > g->n - 1 || at + (size_t)d0 > length) return 0;
        g->degree[x] = (int)d0;
        for (int j = 0; j < g->degree[x]; ++j) {
            int64_t e0 = a[at++];
            if (e0 < 0 || e0 >= g->m) return 0;
            int e = (int)e0;
            if (used[x][e]) return 0;
            used[x][e] = 1; g->rot[x][j] = e; g->local_pos[x][e] = j;
            if (g->u[e] == x) ++occurrence[e][0];
            else if (g->v[e] == x) ++occurrence[e][1];
            else return 0;
        }
    }
    if (at != length) return 0;
    for (int e = 0; e < g->m; ++e)
        if (occurrence[e][0] != 1 || occurrence[e][1] != 1) return 0;

    int reached[MAX_N] = {0}, queue[MAX_N], head = 0, tail = 0;
    reached[g->source] = 1; queue[tail++] = g->source;
    while (head < tail) {
        int x = queue[head++];
        for (int e = 0; e < g->m; ++e) {
            int y = g->u[e] == x ? g->v[e] : (g->v[e] == x ? g->u[e] : -1);
            if (y >= 0 && !reached[y]) { reached[y] = 1; queue[tail++] = y; }
        }
    }
    for (int x = 0; x < g->n; ++x) if (!reached[x]) return 0;

    for (int d = 0; d < 2 * g->m; ++d) g->left_face[d] = -1;
    g->faces = 0;
    for (int start = 0; start < 2 * g->m; ++start) {
        if (g->left_face[start] >= 0) continue;
        int d = start;
        while (g->left_face[d] < 0) {
            g->left_face[d] = g->faces;
            d = next_left_dart(g, d);
            if (d < 0) return 0;
        }
        if (d != start) return 0;
        ++g->faces;
    }
    if (g->faces != g->m - g->n + 2) return 0;
    for (int d = 0; d < 2 * g->m; ++d)
        g->right_face[d] = g->left_face[d ^ 1];
    g->root_anchor = g->rot[g->sink][0];
    int root_dart = 2 * g->root_anchor + (g->v[g->root_anchor] == g->sink);
    g->infinity = g->right_face[root_dart];
    return 1;
}

static void right_first_visit(const PlanarFlow *g, int vertex, int anchor_edge,
                              int is_root, int residual[MAX_N][MAX_N],
                              int seen[MAX_N], int parent[MAX_N], int parent_edge[MAX_N]) {
    int degree = g->degree[vertex];
    int anchor = g->local_pos[vertex][anchor_edge];
    int first = is_root ? 0 : 1;
    for (int step = first; step < first + degree; ++step) {
        int edge = g->rot[vertex][(anchor + step) % degree];
        int neighbor = g->u[edge] == vertex ? g->v[edge] : g->u[edge];
        if (!seen[neighbor] && residual[neighbor][vertex] > 0) {
            seen[neighbor] = 1;
            parent[neighbor] = vertex;
            parent_edge[neighbor] = edge;
            right_first_visit(g, neighbor, edge, 0, residual, seen, parent, parent_edge);
        }
    }
}

static int64_t solve_flow(const PlanarFlow *g) {
    int64_t dual[MAX_FACES][MAX_FACES];
    int64_t distance[MAX_FACES];
    int settled[MAX_FACES] = {0};
    for (int f = 0; f < MAX_FACES; ++f) {
        distance[f] = INF_DIST;
        for (int h = 0; h < MAX_FACES; ++h) dual[f][h] = INF_DIST;
    }
    for (int d = 0; d < 2 * g->m; ++d) {
        int from = g->right_face[d], to = g->left_face[d];
        int64_t length = (d & 1) ? 0 : g->cap[d / 2];
        if (length < dual[from][to]) dual[from][to] = length;
    }
    distance[g->infinity] = 0;
    for (int count = 0; count < g->faces; ++count) {
        int current = -1;
        for (int f = 0; f < g->faces; ++f)
            if (!settled[f] && (current < 0 || distance[f] < distance[current])) current = f;
        if (current < 0 || distance[current] == INF_DIST) break;
        settled[current] = 1;
        for (int f = 0; f < g->faces; ++f) {
            if (dual[current][f] == INF_DIST) continue;
            int64_t candidate = distance[current] + dual[current][f];
            if (candidate < distance[f]) distance[f] = candidate;
        }
    }

    int residual[MAX_N][MAX_N] = {{0}};
    for (int e = 0; e < g->m; ++e) {
        int64_t eta = distance[g->left_face[2 * e]] - distance[g->right_face[2 * e]];
        if (eta < 0 || eta > g->cap[e]) return -1;
        residual[g->u[e]][g->v[e]] += g->cap[e] - (int)eta;
        residual[g->v[e]][g->u[e]] += (int)eta;
    }

    int total = 0;
    for (int augmentation = 0; augmentation <= MAX_AUGMENTATIONS; ++augmentation) {
        int seen[MAX_N] = {0}, parent[MAX_N], parent_edge[MAX_N];
        for (int x = 0; x < g->n; ++x) parent[x] = parent_edge[x] = -1;
        seen[g->sink] = 1;
        right_first_visit(g, g->sink, g->root_anchor, 1, residual, seen, parent, parent_edge);
        if (!seen[g->source]) return total;
        if (augmentation == MAX_AUGMENTATIONS) return -1;
        int delta = INT32_MAX;
        for (int x = g->source; x != g->sink; x = parent[x])
            if (residual[x][parent[x]] < delta) delta = residual[x][parent[x]];
        for (int x = g->source; x != g->sink; x = parent[x]) {
            int y = parent[x];
            residual[x][y] -= delta;
            residual[y][x] += delta;
        }
        total += delta;
    }
    return -1;
}

int64_t planar_directed_general_st_flow_borradaile_klein(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    PlanarFlow graph;
    if (!parse_graph(input, length, &graph)) return -1;
    int64_t value = solve_flow(&graph);
    if (value < 0) return -1;
    if (output == NULL || capacity < 8) return -2;
    uint64_t bits = (uint64_t)value;
    for (int i = 0; i < 8; ++i) output[i] = (uint8_t)(bits >> (8 * i));
    return 8;
}
