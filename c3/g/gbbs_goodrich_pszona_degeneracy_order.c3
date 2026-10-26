module gbbs_goodrich_pszona_degeneracy_order;

const usz MAX_N = 20;
const usz MAX_M = 190;
const usz MAX_INPUT = 2 + 2 * MAX_M;

fn void store_i64_le(char* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

// Clean-room bounded GBBS Goodrich-Pszona degeneracy-order profile.
long gbbs_goodrich_pszona_degeneracy_order(long* input, usz length,
        char* output, usz capacity) @export("gbbs_goodrich_pszona_degeneracy_order") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > (long)MAX_N || m64 < 0 || m64 > (long)MAX_M) return -1;
    usz n = (usz)n64, m = (usz)m64;
    if (length != 2 + 2 * m) return -1;
    bool[MAX_N * MAX_N] adjacent = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        usz u = (usz)u64, v = (usz)v64;
        if (adjacent[u * MAX_N + v]) return -1;
        adjacent[u * MAX_N + v] = true;
        adjacent[v * MAX_N + u] = true;
    }
    if (output == null || capacity < 8 * n) return -2;
    usz[MAX_N] degree = zeroed;
    bool[MAX_N] remaining = zeroed;
    long[MAX_N] rank = zeroed;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        remaining[vertex] = true;
        for (usz neighbor = 0; neighbor < n; neighbor += 1)
            if (adjacent[vertex * MAX_N + neighbor]) degree[vertex] += 1;
    }
    for (usz position = 0; position < n; position += 1) {
        usz chosen = n;
        for (usz vertex = 0; vertex < n; vertex += 1)
            if (remaining[vertex] && (chosen == n || degree[vertex] < degree[chosen])) chosen = vertex;
        rank[chosen] = (long)position;
        remaining[chosen] = false;
        for (usz neighbor = 0; neighbor < n; neighbor += 1)
            if (remaining[neighbor] && adjacent[chosen * MAX_N + neighbor]) degree[neighbor] -= 1;
    }
    for (usz vertex = 0; vertex < n; vertex += 1) store_i64_le(output + 8 * vertex, rank[vertex]);
    return (long)(8 * n);
}
