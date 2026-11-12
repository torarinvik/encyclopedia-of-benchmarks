#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_Q = 32, MAX_EDGES = 15, MAX_OCC = 30, LOG_N = 5 };

static int root_of(int parent[MAX_N], int value) {
    while (parent[value] != value) {
        parent[value] = parent[parent[value]];
        value = parent[value];
    }
    return value;
}

static void point_set(int64_t tree[64], int base, int index, int64_t value) {
    int position = base + index;
    tree[position] = value;
    for (position /= 2; position > 0; position /= 2)
        tree[position] = tree[2 * position] + tree[2 * position + 1];
}

static int64_t range_sum(const int64_t tree[64], int base, int left, int right) {
    if (left > right) return 0;
    int l = base + left, r = base + right + 1;
    int64_t total = 0;
    while (l < r) {
        if (l & 1) total += tree[l++];
        if (r & 1) total += tree[--r];
        l /= 2;
        r /= 2;
    }
    return total;
}

static int lca(int a, int b, const int depth[MAX_N], const int parent[MAX_N],
               const int ancestor[LOG_N][MAX_N]) {
    if (depth[a] < depth[b]) { int t = a; a = b; b = t; }
    int difference = depth[a] - depth[b];
    for (int bit = 0; bit < LOG_N; ++bit)
        if ((difference >> bit) & 1) a = ancestor[bit][a];
    if (a == b) return a;
    for (int bit = LOG_N - 1; bit >= 0; --bit) {
        if (ancestor[bit][a] != ancestor[bit][b]) {
            a = ancestor[bit][a];
            b = ancestor[bit][b];
        }
    }
    return parent[a];
}

int64_t tree_edge_paint_path_count(const int64_t *input, size_t length) {
    if (!input || length < 2 || length > 129) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_Q) return -1;
    const int n = (int)input[0], q = (int)input[1];
    const int m = n - 1;
    if (length != (size_t)(2 + 2 * m + 3 * q)) return -1;

    int edge_u[MAX_EDGES], edge_v[MAX_EDGES], dsu[MAX_N];
    for (int i = 0; i < n; ++i) dsu[i] = i;
    size_t cursor = 2;
    for (int e = 0; e < m; ++e) {
        const int64_t u = input[cursor++], v = input[cursor++];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v) return -1;
        edge_u[e] = (int)u;
        edge_v[e] = (int)v;
        int ru = root_of(dsu, edge_u[e]), rv = root_of(dsu, edge_v[e]);
        if (ru == rv) return -1;
        dsu[ru] = rv;
    }
    for (int v = 1; v < n; ++v) if (root_of(dsu, v) != root_of(dsu, 0)) return -1;

    int parent[MAX_N] = {0}, depth[MAX_N] = {0}, first[MAX_N] = {0};
    int down[MAX_EDGES], up[MAX_EDGES];
    int visited[MAX_N] = {0};
    int stack_node[MAX_N], stack_parent[MAX_N], stack_in[MAX_N], stack_cursor[MAX_N];
    int occurrence_count = 0, top = 0;
    visited[0] = 1;
    stack_node[0] = 0; stack_parent[0] = -1; stack_in[0] = -1; stack_cursor[0] = 0;
    while (top >= 0) {
        int node = stack_node[top], found = 0;
        while (stack_cursor[top] < m) {
            int edge = stack_cursor[top]++;
            if (edge_u[edge] != node && edge_v[edge] != node) continue;
            int child = edge_u[edge] == node ? edge_v[edge] : edge_u[edge];
            if (child == stack_parent[top]) continue;
            if (visited[child]) return -1;
            visited[child] = 1; parent[child] = node; depth[child] = depth[node] + 1;
            down[edge] = occurrence_count++;
            first[child] = occurrence_count;
            ++top; stack_node[top] = child; stack_parent[top] = node;
            stack_in[top] = edge; stack_cursor[top] = 0;
            found = 1; break;
        }
        if (!found) {
            int incoming = stack_in[top--];
            if (incoming >= 0) up[incoming] = occurrence_count++;
        }
    }

    int ancestor[LOG_N][MAX_N] = {{0}};
    for (int v = 0; v < n; ++v) ancestor[0][v] = parent[v];
    for (int k = 1; k < LOG_N; ++k)
        for (int v = 0; v < n; ++v) ancestor[k][v] = ancestor[k - 1][ancestor[k - 1][v]];
    int base = 1;
    while (base < occurrence_count) base *= 2;
    int64_t forward[64] = {0}, backward[64] = {0};
    int painted[MAX_EDGES] = {0};
    int64_t total = 0;
    for (int i = 0; i < q; ++i) {
        int64_t kind = input[cursor++], a = input[cursor++], b = input[cursor++];
        if (kind == 0) {
            if (a < 0 || a >= m || b != 0) return -1;
            if (!painted[a]) {
                painted[a] = 1;
                point_set(forward, base, down[a], 1);
                point_set(backward, base, up[a], 1);
            }
        } else if (kind == 1) {
            if (a < 0 || a >= n || b < 0 || b >= n) return -1;
            int common = lca((int)a, (int)b, depth, parent, ancestor);
            int left_a = first[common], right_a = first[a] - 1;
            int left_b = first[common], right_b = first[b] - 1;
            total += range_sum(forward, base, left_a, right_a) - range_sum(backward, base, left_a, right_a);
            total += range_sum(forward, base, left_b, right_b) - range_sum(backward, base, left_b, right_b);
        } else return -1;
    }
    return total;
}
