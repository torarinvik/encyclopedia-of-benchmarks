#include <stddef.h>
#include <stdint.h>

#define DD_N 6
#define DD_M 10
#define DD_V 8
#define DD_INPUT 63
#define DD_OFFSET 7000

static int dd_member(int owner, int side) { return owner == side || owner == 2; }

static int64_t dd_solve(int side, int n, int m, const int *owner,
                        const int64_t *source_cap, const int64_t *sink_cap,
                        const int *eu, const int *ev, const int64_t *uv,
                        const int64_t *vu, const int64_t *lambda,
                        int64_t scale, int64_t *labels) {
    const int source = n, sink = n + 1, size = n + 2;
    int64_t residual[DD_V][DD_V] = {{0}};
    int64_t constant = 0, flow = 0, source_sum = 0, lambda_sum = 0;
    for (int u = 0; u < n; ++u) if (dd_member(owner[u], side)) {
        int64_t factor = owner[u] == 2 ? scale / 2 : scale;
        residual[source][u] += source_cap[u] * factor;
        residual[u][sink] += sink_cap[u] * factor;
    }
    for (int u = 0; u < n; ++u) source_sum += source_cap[u];
    for (int u = 0; u < n; ++u) if (owner[u] == 2) lambda_sum += lambda[u] < 0 ? -lambda[u] : lambda[u];
    for (int i = 0; i < m; ++i) if (dd_member(owner[eu[i]], side) && dd_member(owner[ev[i]], side)) {
        int64_t factor = owner[eu[i]] == 2 && owner[ev[i]] == 2 ? scale / 2 : scale;
        residual[eu[i]][ev[i]] += uv[i] * factor;
        residual[ev[i]][eu[i]] += vu[i] * factor;
    }
    for (int u = 0; u < n; ++u) if (owner[u] == 2) {
        int64_t q = side == 0 ? lambda[u] : -lambda[u];
        if (q >= 0) residual[source][u] += q;
        else { residual[u][sink] += -q; constant += q; }
    }
    for (;;) {
        int parent[DD_V], queue[DD_V];
        for (int i = 0; i < size; ++i) parent[i] = -1;
        parent[source] = source;
        int head = 0, tail = 0;
        queue[tail++] = source;
        while (head < tail && parent[sink] < 0) {
            int u = queue[head++];
            for (int v = 0; v < size; ++v) if (parent[v] < 0 && residual[u][v] > 0) {
                parent[v] = u; queue[tail++] = v;
                if (v == sink) break;
            }
        }
        if (parent[sink] < 0) {
            for (int u = 0; u < n; ++u) labels[u] = dd_member(owner[u], side) && parent[u] < 0;
            return flow + constant;
        }
        int64_t amount = source_sum * scale + lambda_sum + 1;
        for (int v = sink; v != source; v = parent[v]) if (residual[parent[v]][v] < amount) amount = residual[parent[v]][v];
        for (int v = sink; v != source; v = parent[v]) {
            int u = parent[v]; residual[u][v] -= amount; residual[v][u] += amount;
        }
        flow += amount;
    }
}

int64_t dual_decomposition_graph_cut_maxflow(const int64_t *input, size_t length) {
    static const int64_t scales[9] = {0,2,2,6,12,60,60,420,840};
    if (!input || length < 4 || length > DD_INPUT) return -1;
    int64_t rn = input[0], rm = input[1], ro = input[2], rt = input[3];
    if (rn < 3 || rn > DD_N || rm < 0 || rm > DD_M || ro < 1 || ro > 3 || rt < 1 || rt > 8 ||
        length != 4 + 3 * (size_t)rn + 4 * (size_t)rm) return -1;
    int n = (int)rn, m = (int)rm, overlap = (int)ro, rounds = (int)rt;
    int owner[DD_N], counts[3] = {0};
    size_t at = 4;
    for (int u = 0; u < n; ++u) {
        int64_t x = input[at++]; if (x < 0 || x > 2) return -1;
        owner[u] = (int)x; counts[owner[u]]++;
    }
    if (counts[0] == 0 || counts[1] == 0 || counts[2] != overlap) return -1;
    int64_t source_cap[DD_N], sink_cap[DD_N];
    for (int u = 0; u < n; ++u) { source_cap[u] = input[at++]; if (source_cap[u] < 0 || source_cap[u] > 6 || source_cap[u] % 2) return -1; }
    for (int u = 0; u < n; ++u) { sink_cap[u] = input[at++]; if (sink_cap[u] < 0 || sink_cap[u] > 6 || sink_cap[u] % 2) return -1; }
    int eu[DD_M], ev[DD_M]; int64_t uv[DD_M], vu[DD_M];
    for (int i = 0; i < m; ++i) {
        int64_t u = input[at++], v = input[at++], c = input[at++], d = input[at++];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v ||
            (owner[u] == 0 && owner[v] == 1) || (owner[u] == 1 && owner[v] == 0) ||
            c < 0 || c > 6 || c % 2 || d < 0 || d > 6 || d % 2) return -1;
        eu[i] = (int)u; ev[i] = (int)v; uv[i] = c; vu[i] = d;
    }
    int64_t scale = scales[rounds], lambda[DD_N] = {0}, labels_m[DD_N], labels_n[DD_N];
    int agreement = 0; int64_t dual_scaled = 0;
    for (int iteration = 1; iteration <= rounds; ++iteration) {
        int64_t energy_m = dd_solve(0,n,m,owner,source_cap,sink_cap,eu,ev,uv,vu,lambda,scale,labels_m);
        int64_t energy_n = dd_solve(1,n,m,owner,source_cap,sink_cap,eu,ev,uv,vu,lambda,scale,labels_n);
        dual_scaled = energy_m + energy_n;
        agreement = 1;
        for (int u = 0; u < n; ++u) if (owner[u] == 2 && labels_m[u] != labels_n[u]) agreement = 0;
        if (agreement || iteration == rounds) break;
        int64_t step = scale / iteration;
        for (int u = 0; u < n; ++u) if (owner[u] == 2) lambda[u] += step * (labels_m[u] - labels_n[u]);
    }
    return 2 * (dual_scaled + DD_OFFSET) + agreement;
}
