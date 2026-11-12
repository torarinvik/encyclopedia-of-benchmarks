module baswana_sen_weighted_spanner;

const usz MAX_N = 8;
const usz MAX_M = 28;
const usz MAX_INPUT = 90;

bool edge_before(long aw, long au, long av, long bw, long bu, long bv) {
    return aw < bw || (aw == bw && au < bu) || (aw == bw && au == bu && av < bv);
}

long baswana_sen_weighted_spanner(long* input, usz length, char* output, usz capacity)
        @export("baswana_sen_weighted_spanner") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1], k = input[2];
    if (n64 < 2 || n64 > 8 || m64 < 0 || m64 > 28 || k < 2 || k > 3) return -1;
    usz n = (usz)n64, m = (usz)m64, rounds = (usz)(k - 1);
    if (length != 3 + rounds + 3 * m) return -1;
    long[MAX_N] masks = zeroed;
    for (usz r = 0; r < rounds; r++) {
        masks[r] = input[3 + r];
        if (masks[r] < 0 || masks[r] >= (1 << n64)) return -1;
    }
    long[MAX_M] edge_u = zeroed, edge_v = zeroed, edge_w = zeroed;
    bool[MAX_M] active = zeroed, selected = zeroed;
    usz offset = 3 + rounds;
    for (usz e = 0; e < m; e++) {
        edge_u[e] = input[offset + 3 * e]; edge_v[e] = input[offset + 3 * e + 1]; edge_w[e] = input[offset + 3 * e + 2];
        if (edge_u[e] < 0 || edge_v[e] <= edge_u[e] || edge_v[e] >= n64 || edge_w[e] < 1 || edge_w[e] > 32) return -1;
        for (usz j = 0; j < e; j++) if (edge_u[j] == edge_u[e] && edge_v[j] == edge_v[e]) return -1;
        active[e] = true;
    }
    if (output == null || capacity < m) return -2;
    int[MAX_N] cluster = zeroed, next_cluster = zeroed;
    for (usz v = 0; v < n; v++) cluster[v] = (int)v;
    for (usz r = 0; r < rounds; r++) {
        bool[MAX_N] sampled = zeroed;
        bool[MAX_M] remove = zeroed;
        usz[MAX_N * MAX_N] group_best = zeroed;
        for (usz i = 0; i < MAX_N * MAX_N; i++) group_best[i] = m;
        for (usz v = 0; v < n; v++) next_cluster[v] = -1;
        for (usz v = 0; v < n; v++) {
            int c = cluster[v];
            if (c >= 0 && ((masks[r] >> c) & 1) != 0) sampled[c] = true;
        }
        for (usz v = 0; v < n; v++) if (cluster[v] >= 0 && sampled[cluster[v]]) next_cluster[v] = cluster[v];
        for (usz e = 0; e < m; e++) if (active[e]) {
            usz u = (usz)edge_u[e], v = (usz)edge_v[e];
            if (cluster[v] >= 0) { usz slot = u * MAX_N + (usz)cluster[v]; usz prior = group_best[slot]; if (prior == m || edge_before(edge_w[e], edge_u[e], edge_v[e], edge_w[prior], edge_u[prior], edge_v[prior])) group_best[slot] = e; }
            if (cluster[u] >= 0) { usz slot = v * MAX_N + (usz)cluster[u]; usz prior = group_best[slot]; if (prior == m || edge_before(edge_w[e], edge_u[e], edge_v[e], edge_w[prior], edge_u[prior], edge_v[prior])) group_best[slot] = e; }
        }
        for (usz v = 0; v < n; v++) {
            int old = cluster[v]; if (old < 0 || sampled[old]) continue;
            usz best = m;
            for (usz c = 0; c < n; c++) { usz candidate = group_best[v * MAX_N + c]; if (sampled[c] && candidate != m && (best == m || edge_before(edge_w[candidate], edge_u[candidate], edge_v[candidate], edge_w[best], edge_u[best], edge_v[best]))) best = candidate; }
            if (best == m) {
                for (usz c = 0; c < n; c++) {
                    usz least = group_best[v * MAX_N + c]; if (least == m) continue;
                    selected[least] = true;
                    for (usz e = 0; e < m; e++) if (active[e]) { usz a = (usz)edge_u[e], b = (usz)edge_v[e]; if ((a == v && cluster[b] == (int)c) || (b == v && cluster[a] == (int)c)) remove[e] = true; }
                }
                continue;
            }
            usz a = (usz)edge_u[best], b = (usz)edge_v[best]; int landing = cluster[a == v ? b : a];
            next_cluster[v] = landing; selected[best] = true;
            for (usz c = 0; c < n; c++) {
                usz least = group_best[v * MAX_N + c]; if (least == m) continue;
                bool erase_group = (int)c == landing || edge_w[least] < edge_w[best];
                if ((int)c != landing && edge_w[least] < edge_w[best]) selected[least] = true;
                if (erase_group) for (usz e = 0; e < m; e++) if (active[e]) { usz x = (usz)edge_u[e], y = (usz)edge_v[e]; if ((x == v && cluster[y] == (int)c) || (y == v && cluster[x] == (int)c)) remove[e] = true; }
            }
        }
        for (usz e = 0; e < m; e++) if (remove[e]) active[e] = false;
        for (usz e = 0; e < m; e++) if (active[e]) { usz u = (usz)edge_u[e], v = (usz)edge_v[e]; if (next_cluster[u] >= 0 && next_cluster[u] == next_cluster[v]) active[e] = false; }
        for (usz v = 0; v < n; v++) cluster[v] = next_cluster[v];
    }
    usz[MAX_N * MAX_N] group_best = zeroed;
    for (usz i = 0; i < MAX_N * MAX_N; i++) group_best[i] = m;
    for (usz e = 0; e < m; e++) if (active[e]) {
        usz u = (usz)edge_u[e], v = (usz)edge_v[e];
        if (cluster[v] >= 0) { usz s = u * MAX_N + (usz)cluster[v]; usz prior = group_best[s]; if (prior == m || edge_before(edge_w[e], edge_u[e], edge_v[e], edge_w[prior], edge_u[prior], edge_v[prior])) group_best[s] = e; }
        if (cluster[u] >= 0) { usz s = v * MAX_N + (usz)cluster[u]; usz prior = group_best[s]; if (prior == m || edge_before(edge_w[e], edge_u[e], edge_v[e], edge_w[prior], edge_u[prior], edge_v[prior])) group_best[s] = e; }
    }
    for (usz v = 0; v < n; v++) if (cluster[v] >= 0) for (usz c = 0; c < n; c++) { usz e = group_best[v * MAX_N + c]; if (e != m) selected[e] = true; }
    for (usz e = 0; e < m; e++) { if (selected[e]) output[e] = 1; else output[e] = 0; }
    return (long)m;
}
