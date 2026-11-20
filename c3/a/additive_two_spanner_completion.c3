module additive_two_spanner_completion;
const usz MAX_N = 8; const usz MAX_M = 28; const usz MAX_INPUT = 59; const usz INF = 9;

fn void put(char* out, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { out[at + byte] = (char)(bits & 255); bits >>= 8; }
}

fn void distances(usz n, usz m, usz* u, usz* v, bool* selected, bool only_selected,
                  usz[MAX_N * MAX_N]* d) {
    for (usz a = 0; a < n; a += 1)
        for (usz b = 0; b < n; b += 1) d[a * MAX_N + b] = a == b ? 0 : INF;
    for (usz edge = 0; edge < m; edge += 1) {
        if (only_selected && !selected[edge]) continue;
        d[u[edge] * MAX_N + v[edge]] = 1;
        d[v[edge] * MAX_N + u[edge]] = 1;
    }
    for (usz via = 0; via < n; via += 1)
        for (usz left = 0; left < n; left += 1)
            for (usz right = 0; right < n; right += 1) {
                usz candidate = d[left * MAX_N + via] + d[via * MAX_N + right];
                if (candidate < d[left * MAX_N + right]) d[left * MAX_N + right] = candidate;
            }
}

fn long additive_two_spanner_completion(long* input, usz len, char* output, usz cap)
        @export("additive_two_spanner_completion") {
    if (input == null || len < 2 || len > MAX_INPUT) return -1;
    long n0 = input[0]; long m0 = input[1];
    if (n0 < 1 || n0 > 8 || m0 < 0 || m0 > 28 || len != 2 + 2 * (usz)m0) return -1;
    usz n = (usz)n0; usz m = (usz)m0;
    usz[MAX_M] u = zeroed; usz[MAX_M] v = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long a = input[2 + 2 * edge]; long b = input[3 + 2 * edge];
        if (a < 0 || a >= b || b >= n0) return -1;
        u[edge] = (usz)a; v[edge] = (usz)b;
        for (usz prior = 0; prior < edge; prior += 1)
            if (u[prior] == u[edge] && v[prior] == v[edge]) return -1;
    }
    bool[MAX_M] selected = zeroed;
    usz[MAX_N * MAX_N] original = zeroed;
    distances(n, m, &u, &v, &selected, false, &original);
    for (usz round = 0; round <= m; round += 1) {
        usz[MAX_N * MAX_N] current = zeroed;
        distances(n, m, &u, &v, &selected, true, &current);
        usz source = n; usz target = n;
        for (usz a = 0; a < n && source == n; a += 1)
            for (usz b = a + 1; b < n; b += 1)
                if (original[a * MAX_N + b] < INF && current[a * MAX_N + b] > original[a * MAX_N + b] + 2) {
                    source = a; target = b; break;
                }
        if (source == n) break;
        if (round == m) return -1;
        usz vertex = source;
        while (vertex != target) {
            usz next = n;
            for (usz neighbor = 0; neighbor < n; neighbor += 1) {
                if (neighbor == vertex || original[neighbor * MAX_N + target] + 1 != original[vertex * MAX_N + target]) continue;
                for (usz edge = 0; edge < m; edge += 1)
                    if ((u[edge] == vertex && v[edge] == neighbor) || (v[edge] == vertex && u[edge] == neighbor)) {
                        next = neighbor; selected[edge] = true; break;
                    }
                if (next != n) break;
            }
            if (next == n) return -1;
            vertex = next;
        }
    }
    usz count = 0;
    for (usz edge = 0; edge < m; edge += 1) if (selected[edge]) count += 1;
    usz bytes = 8 * (1 + 2 * count);
    if (output == null || cap < bytes) return -2;
    put(output, 0, (long)count);
    usz slot = 0;
    for (usz edge = 0; edge < m; edge += 1) if (selected[edge]) {
        put(output, 8 * (1 + 2 * slot), (long)u[edge]);
        put(output, 8 * (2 + 2 * slot), (long)v[edge]);
        slot += 1;
    }
    return (long)bytes;
}
