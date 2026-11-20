module kanj_perkovic_modified_yao_spanner;

const long N = 16, M = 42, K = 14, D = 84;
const long MAX_VALID = 312, MAX_PARSEABLE = 313;

fn long kanj_perkovic_modified_yao_spanner(long* input, usz length)
        @export("kanj_perkovic_modified_yao_spanner") {
    if (input == null || length < 2 || length > MAX_PARSEABLE) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 3 || n64 > N || m64 < n64 - 1 || m64 > M ||
        m64 > 3 * n64 - 6 || length != 2 + (usz)n64 + 7 * (usz)m64 || length > MAX_VALID) return -1;
    usz n = (usz)n64, m = (usz)m64, nd = 2 * (usz)m64;
    long[MAX_M] eu, ev, cu, cv, weights;
    bool[MAX_N * MAX_N] adjacent = zeroed;
    long[MAX_N] expected_degree = zeroed;
    long[MAX_D] source, cone;
    for (usz e = 0; e < m; e += 1) {
        usz p = 2 + 5 * e;
        long u = input[p], v = input[p + 1], w = input[p + 2];
        long a = input[p + 3], b = input[p + 4];
        if (u < 0 || u >= v || v >= n64 || w < 1 || w > 1000000000000 ||
            a < 0 || a >= K || b < 0 || b >= K) return -1;
        if (e > 0 && (u < eu[e - 1] || (u == eu[e - 1] && v <= ev[e - 1]))) return -1;
        eu[e] = u; ev[e] = v; weights[e] = w; cu[e] = a; cv[e] = b;
        adjacent[(usz)u * N + (usz)v] = true; adjacent[(usz)v * N + (usz)u] = true;
        expected_degree[(usz)u] += 1; expected_degree[(usz)v] += 1;
        source[2 * e] = u; source[2 * e + 1] = v;
        cone[2 * e] = a; cone[2 * e + 1] = b;
    }
    long[MAX_D] rotation, position;
    long[MAX_N] row_start, degree;
    long[MAX_N * K] first, after;
    bool[MAX_D] seen = zeroed;
    for (usz i = 0; i < N * K; i += 1) { first[i] = -1; after[i] = -1; }
    usz cursor = 2 + 5 * m, used = 0;
    for (usz v = 0; v < n; v += 1) {
        long raw_degree = input[cursor]; cursor += 1;
        if (raw_degree < 1 || raw_degree != expected_degree[v] || raw_degree > D) return -1;
        usz d = (usz)raw_degree; row_start[v] = (long)used; degree[v] = (long)d;
        long previous = -1;
        for (usz j = 0; j < d; j += 1) {
            long raw = input[cursor]; cursor += 1;
            if (raw < 0 || (usz)raw >= nd) return -1;
            usz dart = (usz)raw, c = (usz)cone[dart], slot = v * K + c;
            if (seen[dart] || source[dart] != (long)v || (long)c < previous) return -1;
            previous = (long)c; seen[dart] = true; rotation[used] = (long)dart; position[dart] = (long)used;
            if (first[slot] < 0) first[slot] = (long)used;
            after[slot] = (long)(used + 1); used += 1;
        }
    }
    if (cursor != length || used != nd) return -1;
    for (usz d = 0; d < nd; d += 1) if (!seen[d]) return -1;
    bool[MAX_N] reached = zeroed; long[MAX_N] queue;
    usz head = 0, tail = 0; queue[tail] = 0; tail += 1; reached[0] = true;
    while (head < tail) {
        usz u = (usz)queue[head]; head += 1;
        for (usz v = 0; v < n; v += 1) if (adjacent[u * N + v] && !reached[v]) {
            reached[v] = true; queue[tail] = (long)v; tail += 1;
        }
    }
    if (tail != n) return -1;
    long[MAX_D] next_face; bool[MAX_D] face_seen = zeroed; long faces = 0;
    for (usz d = 0; d < nd; d += 1) {
        usz twin = d ^ 1, dest = (usz)source[twin];
        usz local = (usz)(position[twin] - row_start[dest]);
        usz before = (local + (usz)degree[dest] - 1) % (usz)degree[dest];
        next_face[d] = rotation[(usz)row_start[dest] + before];
    }
    for (usz d = 0; d < nd; d += 1) if (!face_seen[d]) {
        faces += 1; usz x = d;
        while (!face_seen[x]) { face_seen[x] = true; x = (usz)next_face[x]; }
        if (x != d) return -1;
    }
    if ((long)n - (long)m + faces != 2) return -1;

    bool[MAX_D] selected = zeroed;
    for (usz v = 0; v < n; v += 1) for (usz c = 0; c < K; c += 1) {
        usz slot = v * K + c; if (first[slot] < 0) continue;
        long best = -1;
        for (usz p = (usz)first[slot]; p < (usz)after[slot]; p += 1) {
            usz d = (usz)rotation[p], e = d / 2;
            if (best < 0 || weights[e] < weights[(usz)best / 2] ||
                (weights[e] == weights[(usz)best / 2] && (long)e < best / 2)) best = (long)d;
        }
        selected[(usz)best] = true;
    }
    for (usz v = 0; v < n; v += 1) {
        bool occupied = false;
        for (usz c = 0; c < K; c += 1) if (first[v * K + c] >= 0) occupied = true;
        if (!occupied) continue;
        for (usz start = 0; start < K; start += 1) {
            if (first[v * K + start] >= 0 || first[v * K + (start + K - 1) % K] < 0) continue;
            usz len = 0; while (len < K && first[v * K + (start + len) % K] < 0) len += 1;
            if (len == 1) {
                usz cw_c = (start + K - 1) % K, ccw_c = (start + 1) % K;
                usz cw = (usz)rotation[(usz)after[v * K + cw_c] - 1];
                usz ccw = (usz)rotation[(usz)first[v * K + ccw_c]];
                if (selected[cw]) selected[ccw] = true;
                else if (selected[ccw]) selected[cw] = true;
                else { usz a = cw / 2, b = ccw / 2; selected[(weights[a] < weights[b] || (weights[a] == weights[b] && a < b)) ? cw : ccw] = true; }
            } else {
                usz cw_left = len / 2, ccw_left = (len + 1) / 2;
                for (usz step = 1; step <= K && cw_left > 0; step += 1) {
                    usz c = (start + K - step) % K, slot = v * K + c;
                    if (first[slot] >= 0) { usz p = (usz)after[slot]; while (p > (usz)first[slot] && cw_left > 0) { p -= 1; usz d = (usz)rotation[p]; if (!selected[d]) { selected[d] = true; cw_left -= 1; } } }
                }
                for (usz step = len; step < len + K && ccw_left > 0; step += 1) {
                    usz c = (start + step) % K, slot = v * K + c;
                    if (first[slot] >= 0) for (usz p = (usz)first[slot]; p < (usz)after[slot] && ccw_left > 0; p += 1) { usz d = (usz)rotation[p]; if (!selected[d]) { selected[d] = true; ccw_left -= 1; } }
                }
            }
        }
    }
    ulong mask = 0;
    for (usz e = 0; e < m; e += 1) if (selected[2 * e] && selected[2 * e + 1]) mask |= (ulong)1 << e;
    return (long)mask;
}
