module dual_decomposition_graph_cut_maxflow;

const int MAX_N = 6;
const int MAX_M = 10;
const int V = 8;
const long OFFSET = 7000;
const long[9] SCALES = {0,2,2,6,12,60,60,420,840};

fn bool dd_member(int owner, int side) { return owner == side || owner == 2; }

fn long dd_solve(int side, int n, int m, int* owner, long* source_cap, long* sink_cap,
        int* eu, int* ev, long* uv, long* vu, long* lambda, long scale, long* labels) {
    int source = n, sink = n + 1, size = n + 2;
    long[V * V] residual = zeroed;
    long constant = 0, flow = 0, source_sum = 0, lambda_sum = 0;
    for (int u = 0; u < n; u++) {
        source_sum += source_cap[u];
        if (dd_member(owner[u], side)) {
            long factor = owner[u] == 2 ? scale / 2 : scale;
            residual[source * V + u] += source_cap[u] * factor;
            residual[u * V + sink] += sink_cap[u] * factor;
        }
        if (owner[u] == 2) lambda_sum += lambda[u] < 0 ? -lambda[u] : lambda[u];
    }
    for (int i = 0; i < m; i++) if (dd_member(owner[eu[i]], side) && dd_member(owner[ev[i]], side)) {
        long factor = owner[eu[i]] == 2 && owner[ev[i]] == 2 ? scale / 2 : scale;
        residual[eu[i] * V + ev[i]] += uv[i] * factor;
        residual[ev[i] * V + eu[i]] += vu[i] * factor;
    }
    for (int u = 0; u < n; u++) if (owner[u] == 2) {
        long q = side == 0 ? lambda[u] : -lambda[u];
        if (q >= 0) residual[source * V + u] += q;
        else { residual[u * V + sink] += -q; constant += q; }
    }
    while (true) {
        int[V] parent = {-1,-1,-1,-1,-1,-1,-1,-1};
        int[V] queue = zeroed;
        parent[source] = source;
        int head = 0, tail = 0;
        queue[tail++] = source;
        while (head < tail && parent[sink] < 0) {
            int u = queue[head++];
            for (int v = 0; v < size; v++) if (parent[v] < 0 && residual[u * V + v] > 0) {
                parent[v] = u; queue[tail++] = v;
                if (v == sink) break;
            }
        }
        if (parent[sink] < 0) {
            for (int u = 0; u < n; u++) labels[u] = dd_member(owner[u], side) && parent[u] < 0 ? 1 : 0;
            return flow + constant;
        }
        long amount = source_sum * scale + lambda_sum + 1;
        for (int v = sink; v != source; v = parent[v]) if (residual[parent[v] * V + v] < amount) amount = residual[parent[v] * V + v];
        for (int v = sink; v != source; v = parent[v]) {
            int u = parent[v]; residual[u * V + v] -= amount; residual[v * V + u] += amount;
        }
        flow += amount;
    }
}

fn long dual_decomposition_graph_cut_maxflow(long* input, usz length) @export("dual_decomposition_graph_cut_maxflow") {
    if (input == null || length < 4 || length > 63) return -1;
    long rn = input[0], rm = input[1], ro = input[2], rt = input[3];
    if (rn < 3 || rn > MAX_N || rm < 0 || rm > MAX_M || ro < 1 || ro > 3 || rt < 1 || rt > 8 ||
        length != 4 + 3 * (usz)rn + 4 * (usz)rm) return -1;
    int n = (int)rn, m = (int)rm, overlap = (int)ro, rounds = (int)rt;
    int[MAX_N] owner = zeroed;
    int[3] counts = zeroed;
    usz at = 4;
    for (int u = 0; u < n; u++) {
        long x = input[at++]; if (x < 0 || x > 2) return -1;
        owner[u] = (int)x; counts[owner[u]]++;
    }
    if (counts[0] == 0 || counts[1] == 0 || counts[2] != overlap) return -1;
    long[MAX_N] source_cap = zeroed, sink_cap = zeroed;
    for (int u = 0; u < n; u++) { source_cap[u] = input[at++]; if (source_cap[u] < 0 || source_cap[u] > 6 || source_cap[u] % 2 != 0) return -1; }
    for (int u = 0; u < n; u++) { sink_cap[u] = input[at++]; if (sink_cap[u] < 0 || sink_cap[u] > 6 || sink_cap[u] % 2 != 0) return -1; }
    int[MAX_M] eu = zeroed, ev = zeroed;
    long[MAX_M] uv = zeroed, vu = zeroed;
    for (int i = 0; i < m; i++) {
        long ru = input[at++], rv = input[at++], c = input[at++], d = input[at++];
        if (ru < 0 || ru >= rn || rv < 0 || rv >= rn || ru == rv ||
            (owner[(int)ru] == 0 && owner[(int)rv] == 1) || (owner[(int)ru] == 1 && owner[(int)rv] == 0) ||
            c < 0 || c > 6 || c % 2 != 0 || d < 0 || d > 6 || d % 2 != 0) return -1;
        eu[i] = (int)ru; ev[i] = (int)rv; uv[i] = c; vu[i] = d;
    }
    long scale = SCALES[rounds];
    long[MAX_N] lambda = zeroed, labels_m = zeroed, labels_n = zeroed;
    bool agreement = false;
    long dual_scaled = 0;
    for (int iteration = 1; iteration <= rounds; iteration++) {
        long energy_m = dd_solve(0,n,m,&owner[0],&source_cap[0],&sink_cap[0],&eu[0],&ev[0],&uv[0],&vu[0],&lambda[0],scale,&labels_m[0]);
        long energy_n = dd_solve(1,n,m,&owner[0],&source_cap[0],&sink_cap[0],&eu[0],&ev[0],&uv[0],&vu[0],&lambda[0],scale,&labels_n[0]);
        dual_scaled = energy_m + energy_n;
        agreement = true;
        for (int u = 0; u < n; u++) if (owner[u] == 2 && labels_m[u] != labels_n[u]) agreement = false;
        if (agreement || iteration == rounds) break;
        long step = scale / iteration;
        for (int u = 0; u < n; u++) if (owner[u] == 2) lambda[u] += step * (labels_m[u] - labels_n[u]);
    }
    return 2 * (dual_scaled + OFFSET) + (agreement ? 1 : 0);
}
