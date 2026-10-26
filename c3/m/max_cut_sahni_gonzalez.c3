module max_cut_sahni_gonzalez;

const usz MAX_N = 16;
const usz MAX_M = 120;
const usz MAX_INPUT = 362;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long max_cut_sahni_gonzalez(long* input, usz length, char* output, usz capacity)
        @export("max_cut_sahni_gonzalez") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > (long)MAX_N || m64 < 0 || m64 > (long)MAX_M ||
        length != 2 + 3 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64;
    long[MAX_N][MAX_N] weights = zeroed;
    bool[MAX_N][MAX_N] seen = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long u64 = input[2 + 3 * edge], v64 = input[3 + 3 * edge], weight = input[4 + 3 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64 || weight < 0 || weight > 10000) return -1;
        usz u = (usz)u64, v = (usz)v64;
        if (seen[u][v]) return -1;
        seen[u][v] = true;
        weights[u][v] = weight;
        weights[v][u] = weight;
    }
    usz output_bytes = 8 * (n + 1);
    if (output == null || capacity < output_bytes) return -2;
    long[MAX_N] side = zeroed;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        long put_zero = 0, put_one = 0;
        for (usz prior = 0; prior < vertex; prior += 1) {
            if (side[prior] == 1) put_zero += weights[prior][vertex];
            else put_one += weights[prior][vertex];
        }
        side[vertex] = put_one > put_zero ? 1 : 0;
    }
    long cut = 0;
    for (usz u = 0; u < n; u += 1)
        for (usz v = u + 1; v < n; v += 1)
            if (side[u] != side[v]) cut += weights[u][v];
    store_i64_le(output, 0, cut);
    for (usz vertex = 0; vertex < n; vertex += 1) store_i64_le(output, 8 * (vertex + 1), side[vertex]);
    return (long)output_bytes;
}
