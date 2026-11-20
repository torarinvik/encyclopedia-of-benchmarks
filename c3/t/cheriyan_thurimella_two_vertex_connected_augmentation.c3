module cheriyan_thurimella_two_vertex_connected_augmentation;
const usz MAX_N = 8; const usz MAX_M = 28; const usz MAX_INPUT = 59;

fn void put(char* out, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        out[at + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn bool biconnected(usz n, usz m, usz* u, usz* v, bool* active) {
    for (usz removed = 0; removed < n; removed += 1) {
        bool[MAX_N] seen = zeroed;
        usz[MAX_N] queue = zeroed;
        usz start = removed == 0 ? 1 : 0;
        usz head = 0; usz tail = 1;
        seen[start] = true; queue[0] = start;
        while (head < tail) {
            usz current = queue[head]; head += 1;
            for (usz e = 0; e < m; e += 1) {
                if (!active[e] || u[e] == removed || v[e] == removed) continue;
                usz next = n;
                if (u[e] == current) next = v[e];
                else if (v[e] == current) next = u[e];
                if (next < n && !seen[next]) {
                    seen[next] = true; queue[tail] = next; tail += 1;
                }
            }
        }
        for (usz vertex = 0; vertex < n; vertex += 1)
            if (vertex != removed && !seen[vertex]) return false;
    }
    return true;
}

fn long cheriyan_thurimella_two_vertex_connected_augmentation(long* input, usz len,
        char* output, usz cap) @export("cheriyan_thurimella_two_vertex_connected_augmentation") {
    if (input == null || len < 2 || len > MAX_INPUT) return -1;
    long n0 = input[0]; long m0 = input[1];
    if (n0 < 3 || n0 > 8 || m0 < 3 || m0 > 28 || len != 2 + 2 * (usz)m0) return -1;
    usz n = (usz)n0; usz m = (usz)m0;
    usz[MAX_M] u = zeroed; usz[MAX_M] v = zeroed;
    for (usz e = 0; e < m; e += 1) {
        long a = input[2 + 2*e]; long b = input[3 + 2*e];
        if (a < 0 || a >= b || b >= n0) return -1;
        u[e] = (usz)a; v[e] = (usz)b;
        for (usz j = 0; j < e; j += 1)
            if (u[j] == u[e] && v[j] == v[e]) return -1;
    }
    bool[MAX_M] active = zeroed;
    for (usz e = 0; e < m; e += 1) active[e] = true;
    if (!biconnected(n, m, &u[0], &v[0], &active[0])) return -1;

    usz states = (usz)1 << n;
    int[256] best = zeroed; int[256] choice = zeroed;
    for (usz mask = 0; mask < states; mask += 1) choice[mask] = -1;
    for (usz mask = 1; mask < states; mask += 1) {
        usz first = 0;
        while ((mask & ((usz)1 << first)) == 0) first += 1;
        for (usz e = 0; e < m; e += 1) {
            usz other = n;
            if (u[e] == first) other = v[e];
            else if (v[e] == first) other = u[e];
            if (other == n || (mask & ((usz)1 << other)) == 0) continue;
            usz rest = mask & ~((usz)1 << first) & ~((usz)1 << other);
            int candidate = 1 + best[rest];
            if (candidate > best[mask]) { best[mask] = candidate; choice[mask] = (int)e; }
        }
        usz rest = mask & ~((usz)1 << first);
        if (best[rest] > best[mask]) { best[mask] = best[rest]; choice[mask] = -1; }
    }
    bool[MAX_M] cover = zeroed; bool[MAX_N] covered = zeroed;
    usz mask = states - 1;
    while (mask != 0) {
        usz first = 0;
        while ((mask & ((usz)1 << first)) == 0) first += 1;
        int edge = choice[mask];
        if (edge < 0) { mask &= ~((usz)1 << first); continue; }
        usz e = (usz)edge;
        cover[e] = true; covered[u[e]] = true; covered[v[e]] = true;
        mask &= ~((usz)1 << u[e]) & ~((usz)1 << v[e]);
    }
    for (usz vertex = 0; vertex < n; vertex += 1) {
        if (covered[vertex]) continue;
        for (usz e = 0; e < m; e += 1) {
            if (u[e] == vertex || v[e] == vertex) {
                cover[e] = true; covered[u[e]] = true; covered[v[e]] = true; break;
            }
        }
    }
    for (usz e = 0; e < m; e += 1) {
        if (cover[e]) continue;
        active[e] = false;
        if (!biconnected(n, m, &u[0], &v[0], &active[0])) active[e] = true;
    }
    usz count = 0;
    for (usz e = 0; e < m; e += 1) if (active[e]) count += 1;
    usz bytes = 8 * (1 + 2 * count);
    if (output == null || cap < bytes) return -2;
    put(output, 0, (long)count);
    usz slot = 0;
    for (usz e = 0; e < m; e += 1) if (active[e]) {
        put(output, 8 * (1 + 2*slot), (long)u[e]);
        put(output, 8 * (2 + 2*slot), (long)v[e]);
        slot += 1;
    }
    return (long)bytes;
}
