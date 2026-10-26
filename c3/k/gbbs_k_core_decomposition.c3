module gbbs_k_core_decomposition;

const long MAX_N = 16;
const long MAX_M = 64;
const long MAX_INPUT = 130;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

// Clean-room bounded GBBS k-core profile; see package LICENSE.txt.
long gbbs_k_core_decomposition(long* input, usz length, char* output, usz capacity)
        @export("gbbs_k_core_decomposition") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64;
    bool[MAX_N * MAX_N] adjacent = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        usz u = (usz)u64, v = (usz)v64;
        if (adjacent[u * MAX_N + v]) return -1;
        adjacent[u * MAX_N + v] = true;
        adjacent[v * MAX_N + u] = true;
    }
    usz output_bytes = 8 * n;
    if (output == null || capacity < output_bytes) return -2;

    long[MAX_N] degree = zeroed;
    long[MAX_N] core = zeroed;
    bool[MAX_N] alive = zeroed;
    bool[MAX_N] shell = zeroed;
    for (usz u = 0; u < n; u += 1) {
        alive[u] = true;
        for (usz v = 0; v < n; v += 1)
            if (adjacent[u * MAX_N + v]) degree[u] += 1;
    }
    usz remaining = n;
    while (remaining > 0) {
        long k = (long)n;
        for (usz u = 0; u < n; u += 1)
            if (alive[u] && degree[u] < k) k = degree[u];
        for (usz u = 0; u < n; u += 1) {
            shell[u] = alive[u] && degree[u] == k;
            if (shell[u]) { alive[u] = false; core[u] = k; remaining -= 1; }
        }
        for (usz v = 0; v < n; v += 1) {
            if (!alive[v]) continue;
            long removed = 0;
            for (usz u = 0; u < n; u += 1)
                if (shell[u] && adjacent[u * MAX_N + v]) removed += 1;
            if (removed > 0) {
                long next = degree[v] - removed;
                degree[v] = next < k ? k : next;
            }
        }
    }
    for (usz u = 0; u < n; u += 1) store_i64_le(output, 8 * u, core[u]);
    return (long)output_bytes;
}
