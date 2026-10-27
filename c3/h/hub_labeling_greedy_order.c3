module hub_labeling_greedy_order;

const long MAX_N = 8, MAX_M = 28, MAX_OUT = 81;

fn bool is_ancestor(int[MAX_N][MAX_N]* parent, int source, int a, int target) {
    int v = target;
    while (v >= 0) { if (v == a) return true; if (v == source) break; v = parent[source][v]; }
    return false;
}
fn void put_i64(char* out, usz pos, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) out[pos+b] = (char)((bits >> (8*b)) & 255);
}

fn long hub_labeling_greedy_order(long* input, usz length, char* output, usz capacity)
    @export("hub_labeling_greedy_order") {
    if (input == null || length < 2 || length > 58) return -1;
    long n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > MAX_N || m0 < 0 || m0 > n0*(n0-1)/2 || length != 2 + 2*m0.usz()) return -1;
    int n = n0.int(), m = m0.int();
    bool[MAX_N][MAX_N] adj = zeroed;
    long prev_u = -1, prev_v = -1;
    for (int e = 0; e < m; e++) {
        long u = input[2+2*e], v = input[3+2*e];
        if (u < 0 || v <= u || v >= n || (e > 0 && (u < prev_u || (u == prev_u && v <= prev_v)))) return -1;
        adj[u.int()][v.int()] = true; adj[v.int()][u.int()] = true; prev_u = u; prev_v = v;
    }
    int[MAX_N][MAX_N] parent, depth, ways;
    for (int s = 0; s < n; s++) {
        for (int v = 0; v < n; v++) { parent[s][v] = -1; depth[s][v] = -1; ways[s][v] = 0; }
        int[MAX_N] queue; int head = 0, tail = 0;
        queue[tail++] = s; depth[s][s] = 0; ways[s][s] = 1;
        while (head < tail) {
            int u = queue[head++];
            for (int v = 0; v < n; v++) if (adj[u][v]) {
                if (depth[s][v] < 0) { depth[s][v] = depth[s][u]+1; parent[s][v] = u; ways[s][v] = ways[s][u]; queue[tail++] = v; }
                else if (depth[s][v] == depth[s][u]+1) { ways[s][v] += ways[s][u]; if (ways[s][v] > 2) ways[s][v] = 2; }
            }
        }
        for (int v = 0; v < n; v++) if (depth[s][v] < 0 || ways[s][v] != 1) return -1;
    }
    bool[MAX_N][MAX_N] active; for (int s = 0; s < n; s++) for (int t = 0; t < n; t++) active[s][t] = true;
    int[MAX_N] order, rank;
    for (int turn = 0; turn < n; turn++) {
        int[MAX_N] counts = zeroed;
        for (int s = 0; s < n; s++) for (int t = 0; t < n; t++) if (active[s][t]) {
            int x = t; while (x >= 0) { counts[x]++; if (x == s) break; x = parent[s][x]; }
        }
        int best = 0; for (int v = 1; v < n; v++) if (counts[v] > counts[best]) best = v;
        order[turn] = best; rank[best] = turn;
        for (int s = 0; s < n; s++) for (int t = 0; t < n; t++) if (active[s][t] && is_ancestor(&parent,s,best,t)) active[s][t] = false;
    }
    bool[MAX_N][MAX_N] has = zeroed; int[MAX_N][MAX_N] label_dist = zeroed;
    for (int u = 0; u < n; u++) for (int v = u; v < n; v++) {
        int[MAX_N] path; int plen = 0, x = v;
        while (x >= 0) { path[plen++] = x; if (x == u) break; x = parent[u][x]; }
        if (x < 0) return -1;
        int hub = path[0]; for (int i = 1; i < plen; i++) if (rank[path[i]] < rank[hub]) hub = path[i];
        has[u][hub] = true; has[v][hub] = true; label_dist[u][hub] = depth[u][hub]; label_dist[v][hub] = depth[v][hub];
    }
    long[MAX_OUT] staged; usz used = 0;
    staged[used++] = n; for (int i = 0; i < n; i++) staged[used++] = order[i];
    for (int v = 0; v < n; v++) {
        int count = 0; for (int h = 0; h < n; h++) if (has[v][h]) count++;
        staged[used++] = count;
        for (int h = 0; h < n; h++) if (has[v][h]) staged[used++] = h | (label_dist[v][h] << 8);
    }
    usz required = used * 8;
    if (output == null || capacity < required) return -2;
    for (usz i = 0; i < used; i++) put_i64(output, i*8, staged[i]);
    return required.long();
}
