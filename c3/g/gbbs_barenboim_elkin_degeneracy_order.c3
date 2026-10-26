// Clean-room bounded GBBS Barenboim-Elkin profile; see package LICENSE.txt.
module gbbs_barenboim_elkin_degeneracy_order;
const usz MAX_N = 20;
const usz MAX_M = 190;
const usz MAX_INPUT = 382;

fn void store_i64_le(char* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[byte] = (char)(bits & 255); bits >>= 8; }
}

long gbbs_barenboim_elkin_degeneracy_order(long* input, usz length,
        char* output, usz capacity) @export("gbbs_barenboim_elkin_degeneracy_order") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > 20 || m64 < 0 || m64 > 190) return -1;
    usz n = (usz)n64, m = (usz)m64;
    if (length != 2 + 2 * m) return -1;
    bool[MAX_N * MAX_N] adjacent = zeroed;
    long[MAX_N] initial_degree = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return -1;
        usz u = (usz)u64, v = (usz)v64;
        if (adjacent[u * MAX_N + v]) return -1;
        adjacent[u * MAX_N + v] = true; adjacent[v * MAX_N + u] = true;
        initial_degree[u] += 1; initial_degree[v] += 1;
    }
    if (output == null || capacity < 8 * n) return -2;

    long[MAX_N] degree = zeroed;
    bool[MAX_N] alive = zeroed;
    for (usz v = 0; v < n; v += 1) { degree[v] = initial_degree[v]; alive[v] = true; }
    usz remaining = n;
    long best_num = 0, best_den = 1;
    while (remaining > 0) {
        long total = 0;
        for (usz v = 0; v < n; v += 1) if (alive[v]) total += degree[v];
        if (total * best_den > best_num * (long)remaining) { best_num = total; best_den = (long)remaining; }
        bool[MAX_N] removed = zeroed;
        usz count = 0;
        for (usz v = 0; v < n; v += 1) {
            if (alive[v] && 10 * degree[v] * (long)remaining <= 11 * total) { removed[v] = true; count += 1; }
        }
        if (count == 0) return -1;
        for (usz v = 0; v < n; v += 1) if (removed[v]) alive[v] = false;
        remaining -= count;
        for (usz v = 0; v < n; v += 1) if (alive[v]) {
            long decrement = 0;
            for (usz u = 0; u < n; u += 1) if (removed[u] && adjacent[v * MAX_N + u]) decrement += 1;
            degree[v] -= decrement;
        }
    }
    long cutoff = (best_num + 10 * best_den - 1) / (10 * best_den);
    if (cutoff < 1) cutoff = 1;
    for (usz v = 0; v < n; v += 1) { degree[v] = initial_degree[v]; alive[v] = true; }
    usz[MAX_N] order = zeroed;
    usz used = 0;
    while (used < n) {
        usz[MAX_N] shell = zeroed;
        usz count = 0;
        for (usz v = 0; v < n; v += 1) if (alive[v] && degree[v] < cutoff) { shell[count] = v; count += 1; }
        if (count == 0) { for (usz v = 0; v < n; v += 1) if (alive[v]) { shell[count] = v; count += 1; break; } }
        for (usz i = 0; i < count; i += 1) { alive[shell[i]] = false; order[used] = shell[i]; used += 1; }
        for (usz v = 0; v < n; v += 1) if (alive[v]) {
            long decrement = 0;
            for (usz i = 0; i < count; i += 1) if (adjacent[v * MAX_N + shell[i]]) decrement += 1;
            degree[v] -= decrement;
        }
    }
    long[MAX_N] rank = zeroed;
    for (usz i = 0; i < n; i += 1) rank[order[i]] = (long)i;
    for (usz v = 0; v < n; v += 1) store_i64_le(output + 8 * v, rank[v]);
    return (long)(8 * n);
}
