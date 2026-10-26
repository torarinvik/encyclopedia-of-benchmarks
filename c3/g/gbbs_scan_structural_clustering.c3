module gbbs_scan_structural_clustering;

const usz MAX_N = 16;
const usz MAX_M = 64;
const usz MAX_INPUT = 130;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn void similarity_parts(usz u, usz v, bool* adjacent, usz* degree,
                         usz* numerator, usz* denominator_sq) {
    usz shared = 0;
    for (usz w = 0; w < MAX_N; w += 1) {
        if (adjacent[u * MAX_N + w] && adjacent[v * MAX_N + w]) shared += 1;
    }
    *numerator = shared + 2;
    *denominator_sq = (degree[u] + 1) * (degree[v] + 1);
}

fn bool epsilon_similar(usz numerator, usz denominator_sq) {
    return 4 * numerator * numerator >= denominator_sq;
}

// Clean-room bounded GBBS SCAN profile; see package LICENSE.txt.
long gbbs_scan_structural_clustering(long* input, usz length, char* output,
        usz capacity) @export("gbbs_scan_structural_clustering") {
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
    usz output_bytes = 8 * n;
    if (output == null || capacity < output_bytes) return -2;

    bool[MAX_N] core = zeroed;
    long[MAX_N] labels = zeroed;
    for (usz u = 0; u < n; u += 1) {
        usz similar_count = 0;
        for (usz v = 0; v < n; v += 1) {
            if (adjacent[u * MAX_N + v]) {
                usz numerator = 0, denominator_sq = 1;
                similarity_parts(u, v, &adjacent[0], &degree[0], &numerator, &denominator_sq);
                if (epsilon_similar(numerator, denominator_sq)) similar_count += 1;
            }
        }
        core[u] = similar_count >= 2;
        labels[u] = -1;
    }
    for (usz root = 0; root < n; root += 1) {
        if (!core[root] || labels[root] != -1) continue;
        usz[MAX_N] queue = zeroed;
        usz head = 0, tail = 1;
        labels[root] = (long)root;
        queue[0] = root;
        while (head < tail) {
            usz u = queue[head];
            head += 1;
            for (usz v = 0; v < n; v += 1) {
                if (!core[v] || labels[v] != -1 || !adjacent[u * MAX_N + v]) continue;
                usz numerator = 0, denominator_sq = 1;
                similarity_parts(u, v, &adjacent[0], &degree[0], &numerator, &denominator_sq);
                if (epsilon_similar(numerator, denominator_sq)) {
                    labels[v] = (long)root;
                    queue[tail] = v;
                    tail += 1;
                }
            }
        }
    }
    for (usz u = 0; u < n; u += 1) {
        if (core[u]) continue;
        usz best_core = MAX_N, best_num = 0, best_den = 1;
        for (usz v = 0; v < n; v += 1) {
            if (!core[v] || !adjacent[u * MAX_N + v]) continue;
            usz numerator = 0, denominator_sq = 1;
            similarity_parts(u, v, &adjacent[0], &degree[0], &numerator, &denominator_sq);
            if (!epsilon_similar(numerator, denominator_sq)) continue;
            usz left = numerator * numerator * best_den;
            usz right = best_num * best_num * denominator_sq;
            if (best_core == MAX_N || left > right || (left == right && v < best_core)) {
                best_core = v;
                best_num = numerator;
                best_den = denominator_sq;
            }
        }
        if (best_core != MAX_N) labels[u] = labels[best_core];
    }
    for (usz v = 0; v < n; v += 1) store_i64_le(output, 8 * v, labels[v]);
    return (long)output_bytes;
}
