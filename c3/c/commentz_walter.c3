module commentz_walter;

const int CW_P = 6, CW_L = 8, CW_T = 64, CW_NODES = 33, CW_INPUT = 105;

fn bool cw_is_suffix(int v, int u, int* depth, int* path) {
    if (depth[v] >= depth[u]) return false;
    int offset = depth[u] - depth[v];
    for (int i = 0; i < depth[v]; i++)
        if (path[v * CW_L + i] != path[u * CW_L + offset + i]) return false;
    return true;
}

fn long commentz_walter(long* values, usz length) @export("commentz_walter") {
    if (values == null || length < 2 || length > CW_INPUT) return -1;
    long pv = values[0], nv = values[1];
    if (pv < 1 || pv > CW_P || nv < 0 || nv > CW_T) return -1;
    int p = (int)pv, n = (int)nv;
    int[CW_P] lens = zeroed;
    int total = 0, shortest = CW_L + 1;
    if (length < (usz)(2 + p)) return -1;
    for (int i = 0; i < p; i++) {
        long raw = values[2 + i];
        if (raw < 1 || raw > CW_L) return -1;
        lens[i] = (int)raw;
        total += lens[i];
        if (lens[i] < shortest) shortest = lens[i];
    }
    if (total > 32 || length != (usz)(2 + p + total + n)) return -1;
    long[CW_P * CW_L] patterns = zeroed;
    long[CW_T] text = zeroed;
    usz at = (usz)(2 + p);
    for (int i = 0; i < p; i++) {
        for (int j = 0; j < lens[i]; j++) {
            long symbol = values[at++];
            if (symbol < 1 || symbol > 4) return -1;
            patterns[i * CW_L + j] = symbol;
        }
        for (int prior = 0; prior < i; prior++) {
            if (lens[prior] != lens[i]) continue;
            bool same = true;
            for (int j = 0; j < lens[i]; j++)
                if (patterns[prior * CW_L + j] != patterns[i * CW_L + j]) same = false;
            if (same) return -1;
        }
    }
    for (int i = 0; i < n; i++) {
        long symbol = values[at++];
        if (symbol < 1 || symbol > 4) return -1;
        text[i] = symbol;
    }

    int[CW_NODES * 5] child = zeroed;
    int[CW_NODES] parent = zeroed, label = zeroed, depth = zeroed, terminal = zeroed;
    int[CW_NODES * CW_L] path = zeroed;
    int nodes = 1;
    for (int i = 0; i < p; i++) {
        int v = 0;
        for (int j = lens[i] - 1; j >= 0; j--) {
            int symbol = (int)patterns[i * CW_L + j];
            int at_child = v * 5 + symbol;
            int encoded = child[at_child];
            if (encoded == 0) {
                int u = nodes++;
                child[at_child] = u + 1;
                parent[u] = v;
                label[u] = symbol;
                depth[u] = depth[v] + 1;
                for (int k = 0; k < depth[v]; k++) path[u * CW_L + k] = path[v * CW_L + k];
                path[u * CW_L + depth[v]] = symbol;
                encoded = u + 1;
            }
            v = encoded - 1;
        }
        terminal[v] = 1;
    }

    int[CW_NODES] shift1 = zeroed, shift2 = zeroed;
    int[5] bad = zeroed;
    for (int v = 0; v < nodes; v++) { shift1[v] = shortest; shift2[v] = shortest; }
    shift1[0] = 1;
    for (int a = 0; a <= 4; a++) bad[a] = shortest + 1;
    for (int v = 1; v < nodes; v++) {
        if (depth[v] < bad[label[v]]) bad[label[v]] = depth[v];
        shift2[v] = shift2[parent[v]];
        for (int u = 1; u < nodes; u++) {
            if (cw_is_suffix(v, u, &depth[0], &path[0])) {
                int delta = depth[u] - depth[v];
                if (delta < shift1[v]) shift1[v] = delta;
                if (terminal[u] && delta < shift2[v]) shift2[v] = delta;
            }
        }
    }

    long matches = 0;
    int position = shortest - 1;
    while (position < n) {
        int v = 0, i = position;
        while (i >= 0) {
            int encoded = child[v * 5 + (int)text[i]];
            if (encoded == 0) break;
            v = encoded - 1;
            i--;
            if (terminal[v]) matches++;
        }
        int symbol = i >= 0 ? (int)text[i] : 0;
        int char_shift = symbol == 0 ? shortest + 1 : bad[symbol];
        int delta = char_shift - depth[v] - 1;
        if (delta < shift1[v]) delta = shift1[v];
        if (delta > shift2[v]) delta = shift2[v];
        position += delta;
    }
    return matches;
}
