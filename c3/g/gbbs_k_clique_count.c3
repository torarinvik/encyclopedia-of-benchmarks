module gbbs_k_clique_count;

const usz MAX_N = 24;
const usz MAX_M = 64;
const usz MAX_INPUT = 130;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

// Clean-room GBBS fixed-k clique profile; see package LICENSE.txt.
long gbbs_k_clique_count(long* input, usz length, char* output, usz capacity)
        @export("gbbs_k_clique_count") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > (long)MAX_N || m64 < 0 || m64 > (long)MAX_M) return -1;
    usz n = (usz)n64, m = (usz)m64;
    if (length != 2 + 2 * m) return -1;
    bool[MAX_N * MAX_N] adjacent = zeroed;
    usz[MAX_N] degree = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        usz u = (usz)u64, v = (usz)v64;
        if (adjacent[u * MAX_N + v]) return -1;
        adjacent[u * MAX_N + v] = true;
        adjacent[v * MAX_N + u] = true;
        degree[u] += 1;
        degree[v] += 1;
    }
    if (output == null || capacity < 8) return -2;

    bool[MAX_N * MAX_N] directed = zeroed;
    for (usz u = 0; u < n; u += 1) {
        if (degree[u] >= 3) {
            for (usz v = u + 1; v < n; v += 1) {
                if (degree[v] >= 3 && adjacent[u * MAX_N + v]) directed[u * MAX_N + v] = true;
            }
        }
    }
    long count = 0;
    for (usz a = 0; a < n; a += 1) {
        for (usz b = a + 1; b < n; b += 1) {
            if (!directed[a * MAX_N + b]) continue;
            for (usz c = b + 1; c < n; c += 1) {
                if (directed[a * MAX_N + c] && directed[b * MAX_N + c]) {
                    for (usz d = c + 1; d < n; d += 1) {
                        if (directed[a * MAX_N + d] && directed[b * MAX_N + d] && directed[c * MAX_N + d]) count += 1;
                    }
                }
            }
        }
    }
    store_i64_le(output, 0, count);
    return 8;
}
