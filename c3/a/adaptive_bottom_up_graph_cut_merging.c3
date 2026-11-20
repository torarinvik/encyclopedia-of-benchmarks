module adaptive_bottom_up_graph_cut_merging;

const int MAX_N = 8;
const int MAX_M = 16;
const int MAX_B = 4;
const int V = 10;

fn bool abm_allowed(int u, int v, int n, int* allowed) {
    if (u < n && allowed[u] == 0) return false;
    if (v < n && allowed[v] == 0) return false;
    if (v == n || u == n + 1) return false;
    return true;
}

fn void abm_augment(long* residual, int n, int* allowed) {
    int source = n, sink = n + 1, size = n + 2;
    while (true) {
        int[MAX_N + 2] parent = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
        int[MAX_N + 2] queue = zeroed;
        parent[source] = source;
        int head = 0, tail = 0;
        queue[tail++] = source;
        while (head < tail && parent[sink] < 0) {
            int u = queue[head++];
            for (int v = 0; v < size; v++) {
                if (parent[v] < 0 && residual[u * V + v] > 0 && abm_allowed(u, v, n, allowed)) {
                    parent[v] = u;
                    queue[tail++] = v;
                    if (v == sink) break;
                }
            }
        }
        if (parent[sink] < 0) return;
        long amount = (long)(n * 7);
        int v = sink;
        while (v != source) {
            int u = parent[v];
            if (residual[u * V + v] < amount) amount = residual[u * V + v];
            v = u;
        }
        v = sink;
        while (v != source) {
            int u = parent[v];
            residual[u * V + v] -= amount;
            residual[v * V + u] += amount;
            v = u;
        }
    }
}

fn long adaptive_bottom_up_graph_cut_merging(long* input, usz length) @export("adaptive_bottom_up_graph_cut_merging") {
    if (input == null || length < 3 || length > 92) return -1;
    long raw_n = input[0], raw_m = input[1], raw_b = input[2];
    if (raw_n < 2 || raw_n > MAX_N || raw_m < 0 || raw_m > MAX_M || raw_b < 1 || raw_b > MAX_B || raw_b > raw_n ||
        length != 3 + 3 * (usz)raw_n + 4 * (usz)raw_m) return -1;
    int n = (int)raw_n, m = (int)raw_m, bcount = (int)raw_b;
    int[MAX_N] block = zeroed;
    bool[MAX_B] seen = zeroed;
    long[MAX_N] source_cap = zeroed, sink_cap = zeroed;
    usz at = 3;
    for (int u = 0; u < n; u++) {
        long x = input[at++];
        if (x < 0 || x >= bcount) return -1;
        block[u] = (int)x; seen[block[u]] = true;
    }
    for (int b = 0; b < bcount; b++) if (!seen[b]) return -1;
    for (int u = 0; u < n; u++) { source_cap[u] = input[at++]; if (source_cap[u] < 0 || source_cap[u] > 7) return -1; }
    for (int u = 0; u < n; u++) { sink_cap[u] = input[at++]; if (sink_cap[u] < 0 || sink_cap[u] > 7) return -1; }

    int[MAX_M] eu = zeroed, ev = zeroed, ba = zeroed, bb = zeroed;
    bool[MAX_M] cross = zeroed, enabled = zeroed;
    long[MAX_M] uv = zeroed, vu = zeroed;
    long[V * V] residual = zeroed;
    for (int u = 0; u < n; u++) { residual[n * V + u] += source_cap[u]; residual[u * V + n + 1] += sink_cap[u]; }
    long[MAX_B * MAX_B] potential = zeroed;
    bool[MAX_B * MAX_B] present = zeroed;
    for (int i = 0; i < m; i++) {
        long ru = input[at++], rv = input[at++], rc = input[at++], rd = input[at++];
        if (ru < 0 || ru >= n || rv < 0 || rv >= n || ru == rv || rc < 0 || rc > 7 || rd < 0 || rd > 7) return -1;
        int u = (int)ru, v = (int)rv;
        eu[i] = u; ev[i] = v; uv[i] = rc; vu[i] = rd;
        if (block[u] == block[v]) {
            residual[u * V + v] += rc; residual[v * V + u] += rd;
        } else {
            ba[i] = block[u] < block[v] ? block[u] : block[v];
            bb[i] = block[u] < block[v] ? block[v] : block[u];
            cross[i] = rc != 0 || rd != 0;
            if (cross[i]) present[ba[i] * MAX_B + bb[i]] = true;
        }
    }

    int[MAX_N] allowed = zeroed;
    for (int b = 0; b < bcount; b++) {
        for (int u = 0; u < n; u++) allowed[u] = block[u] == b;
        abm_augment(&residual[0], n, &allowed[0]);
    }
    int[MAX_N] tag = zeroed;
    for (int b = 0; b < bcount; b++) {
        bool[V] ss = zeroed, tt = zeroed;
        int[V] queue = zeroed;
        for (int u = 0; u < n; u++) allowed[u] = block[u] == b;
        int head = 0, tail = 0; ss[n] = true; queue[tail++] = n;
        while (head < tail) { int u = queue[head++]; for (int v = 0; v < n + 2; v++)
            if (!ss[v] && residual[u * V + v] > 0 && (u >= n || allowed[u] != 0) && (v >= n || allowed[v] != 0)) { ss[v] = true; queue[tail++] = v; } }
        head = 0; tail = 0; tt[n + 1] = true; queue[tail++] = n + 1;
        while (head < tail) { int v = queue[head++]; for (int u = 0; u < n + 2; u++)
            if (!tt[u] && residual[u * V + v] > 0 && (u >= n || allowed[u] != 0) && (v >= n || allowed[v] != 0)) { tt[u] = true; queue[tail++] = u; } }
        for (int u = 0; u < n; u++) if (allowed[u] != 0) tag[u] = ss[u] ? 1 : (tt[u] ? 2 : 0);
    }
    for (int i = 0; i < m; i++) if (cross[i] && tag[eu[i]] != tag[ev[i]]) {
        if (uv[i] > 0) potential[ba[i] * MAX_B + bb[i]] += 1;
        if (vu[i] > 0) potential[ba[i] * MAX_B + bb[i]] += 1;
    }

    int[MAX_B * MAX_B] order_a = zeroed, order_b = zeroed;
    int order_n = 0;
    for (int a = 0; a < bcount; a++) for (int b = a + 1; b < bcount; b++) if (present[a * MAX_B + b]) {
        int pos = order_n++;
        while (pos > 0) {
            int pa = order_a[pos - 1], pb = order_b[pos - 1];
            if (potential[pa * MAX_B + pb] > potential[a * MAX_B + b] ||
                (potential[pa * MAX_B + pb] == potential[a * MAX_B + b] && (pa < a || (pa == a && pb <= b)))) break;
            order_a[pos] = pa; order_b[pos] = pb; pos--;
        }
        order_a[pos] = a; order_b[pos] = b;
    }
    int[MAX_B] parent = {0, 1, 2, 3};
    for (int oi = 0; oi < order_n; oi++) {
        int a = order_a[oi], b = order_b[oi];
        while (parent[a] != a) a = parent[a]; while (parent[b] != b) b = parent[b];
        if (a == b) continue;
        int root = a < b ? a : b, other = a < b ? b : a; parent[other] = root;
        for (int i = 0; i < m; i++) if (cross[i] && !enabled[i]) {
            int x = ba[i], y = bb[i]; while (parent[x] != x) x = parent[x]; while (parent[y] != y) y = parent[y];
            if (x == y) { residual[eu[i] * V + ev[i]] += uv[i]; residual[ev[i] * V + eu[i]] += vu[i]; enabled[i] = true; }
        }
        for (int u = 0; u < n; u++) { int x = block[u]; while (parent[x] != x) x = parent[x]; allowed[u] = x == root; }
        abm_augment(&residual[0], n, &allowed[0]);
    }
    long flow = 0;
    for (int u = 0; u < n; u++) flow += source_cap[u] - residual[n * V + u];
    return flow;
}
