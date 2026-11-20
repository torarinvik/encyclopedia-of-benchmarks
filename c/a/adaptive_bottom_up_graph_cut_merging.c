#include <stddef.h>
#include <stdint.h>

#define ABM_N 8
#define ABM_M 16
#define ABM_B 4
#define ABM_V 10
#define ABM_INPUT 92

static int abm_allowed(int u, int v, int n, const int *allowed) {
    int source = n, sink = n + 1;
    if (u < n && !allowed[u]) return 0;
    if (v < n && !allowed[v]) return 0;
    if (v == source || u == sink) return 0;
    return 1;
}

static void abm_augment(int64_t r[ABM_V][ABM_V], int n, const int *allowed) {
    const int source = n, sink = n + 1, size = n + 2;
    for (;;) {
        int parent[ABM_V], queue[ABM_V];
        for (int i = 0; i < size; ++i) parent[i] = -1;
        parent[source] = source;
        int head = 0, tail = 0;
        queue[tail++] = source;
        while (head < tail && parent[sink] < 0) {
            int u = queue[head++];
            for (int v = 0; v < size; ++v) {
                if (parent[v] < 0 && r[u][v] > 0 && abm_allowed(u, v, n, allowed)) {
                    parent[v] = u;
                    queue[tail++] = v;
                    if (v == sink) break;
                }
            }
        }
        if (parent[sink] < 0) return;
        int64_t amount = (int64_t)n * 7;
        for (int v = sink; v != source; v = parent[v])
            if (r[parent[v]][v] < amount) amount = r[parent[v]][v];
        for (int v = sink; v != source; v = parent[v]) {
            int u = parent[v];
            r[u][v] -= amount;
            r[v][u] += amount;
        }
    }
}

int64_t adaptive_bottom_up_graph_cut_merging(const int64_t *input, size_t length) {
    if (!input || length < 3 || length > ABM_INPUT) return -1;
    int64_t rn = input[0], rm = input[1], rb = input[2];
    if (rn < 2 || rn > ABM_N || rm < 0 || rm > ABM_M || rb < 1 || rb > ABM_B ||
        rb > rn || length != 3 + 3 * (size_t)rn + 4 * (size_t)rm) return -1;
    int n = (int)rn, m = (int)rm, bcount = (int)rb;
    int block[ABM_N], seen[ABM_B] = {0};
    int64_t source_cap[ABM_N], sink_cap[ABM_N];
    size_t at = 3;
    for (int u = 0; u < n; ++u) {
        int64_t x = input[at++];
        if (x < 0 || x >= bcount) return -1;
        block[u] = (int)x; seen[block[u]] = 1;
    }
    for (int b = 0; b < bcount; ++b) if (!seen[b]) return -1;
    for (int u = 0; u < n; ++u) { source_cap[u] = input[at++]; if (source_cap[u] < 0 || source_cap[u] > 7) return -1; }
    for (int u = 0; u < n; ++u) { sink_cap[u] = input[at++]; if (sink_cap[u] < 0 || sink_cap[u] > 7) return -1; }
    int eu[ABM_M], ev[ABM_M], eb0[ABM_M], eb1[ABM_M], cross[ABM_M], enabled[ABM_M] = {0};
    int64_t ecap[ABM_M], erev[ABM_M];
    int64_t residual[ABM_V][ABM_V] = {{0}};
    for (int u = 0; u < n; ++u) { residual[n][u] += source_cap[u]; residual[u][n + 1] += sink_cap[u]; }
    int64_t score[ABM_B][ABM_B] = {{0}};
    int present[ABM_B][ABM_B] = {{0}};
    for (int i = 0; i < m; ++i) {
        int64_t u = input[at++], v = input[at++], c = input[at++], d = input[at++];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v || c < 0 || c > 7 || d < 0 || d > 7) return -1;
        eu[i] = (int)u; ev[i] = (int)v; ecap[i] = c; erev[i] = d;
        if (block[u] == block[v]) {
            cross[i] = 0; eb0[i] = eb1[i] = -1;
            residual[u][v] += c; residual[v][u] += d;
        } else {
            cross[i] = (c != 0 || d != 0);
            eb0[i] = block[u] < block[v] ? block[u] : block[v];
            eb1[i] = block[u] < block[v] ? block[v] : block[u];
            if (cross[i]) present[eb0[i]][eb1[i]] = 1;
        }
    }
    int allowed[ABM_N];
    for (int b = 0; b < bcount; ++b) {
        for (int u = 0; u < n; ++u) allowed[u] = block[u] == b;
        abm_augment(residual, n, allowed);
    }
    int tag[ABM_N] = {0};
    for (int b = 0; b < bcount; ++b) {
        int ss[ABM_V] = {0}, tt[ABM_V] = {0}, q[ABM_V], head, tail;
        for (int u = 0; u < n; ++u) allowed[u] = block[u] == b;
        head = tail = 0; ss[n] = 1; q[tail++] = n;
        while (head < tail) { int u = q[head++]; for (int v = 0; v < ABM_V; ++v)
            if (!ss[v] && residual[u][v] > 0 && (u >= n || allowed[u]) && (v >= n || allowed[v])) { ss[v] = 1; q[tail++] = v; } }
        head = tail = 0; tt[n + 1] = 1; q[tail++] = n + 1;
        while (head < tail) { int v = q[head++]; for (int u = 0; u < ABM_V; ++u)
            if (!tt[u] && residual[u][v] > 0 && (u >= n || allowed[u]) && (v >= n || allowed[v])) { tt[u] = 1; q[tail++] = u; } }
        for (int u = 0; u < n; ++u) if (allowed[u]) tag[u] = ss[u] ? 1 : (tt[u] ? 2 : 0);
    }
    for (int i = 0; i < m; ++i) if (cross[i]) {
        if (tag[eu[i]] != tag[ev[i]]) score[eb0[i]][eb1[i]] += (ecap[i] > 0) + (erev[i] > 0);
    }
    int order_a[ABM_B * ABM_B], order_b[ABM_B * ABM_B], order_n = 0;
    for (int a = 0; a < bcount; ++a) for (int b = a + 1; b < bcount; ++b) if (present[a][b]) {
        int pos = order_n++;
        while (pos > 0) {
            int pa = order_a[pos - 1], pb = order_b[pos - 1];
            if (score[pa][pb] > score[a][b] || (score[pa][pb] == score[a][b] && (pa < a || (pa == a && pb <= b)))) break;
            order_a[pos] = pa; order_b[pos] = pb; --pos;
        }
        order_a[pos] = a; order_b[pos] = b;
    }
    int parent[ABM_B]; for (int b = 0; b < bcount; ++b) parent[b] = b;
    for (int oi = 0; oi < order_n; ++oi) {
        int a = order_a[oi], b = order_b[oi];
        while (parent[a] != a) a = parent[a];
        while (parent[b] != b) b = parent[b];
        if (a == b) continue;
        int root = a < b ? a : b, other = a < b ? b : a;
        parent[other] = root;
        for (int i = 0; i < m; ++i) if (cross[i] && !enabled[i]) {
            int x = eb0[i], y = eb1[i]; while (parent[x] != x) x = parent[x]; while (parent[y] != y) y = parent[y];
            if (x == y) { residual[eu[i]][ev[i]] += ecap[i]; residual[ev[i]][eu[i]] += erev[i]; enabled[i] = 1; }
        }
        for (int u = 0; u < n; ++u) { int x = block[u]; while (parent[x] != x) x = parent[x]; allowed[u] = x == root; }
        abm_augment(residual, n, allowed);
    }
    int64_t flow = 0;
    for (int u = 0; u < n; ++u) flow += source_cap[u] - residual[n][u];
    return flow;
}
