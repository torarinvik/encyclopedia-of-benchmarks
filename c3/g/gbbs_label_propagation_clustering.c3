module gbbs_label_propagation_clustering;

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

// Clean-room bounded GBBS label-propagation profile; see package LICENSE.txt.
long gbbs_label_propagation_clustering(long* input, usz length,
        char* output, usz capacity) @export("gbbs_label_propagation_clustering") {
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
    usz output_bytes = 8 * n;
    if (output == null || capacity < output_bytes) return -2;

    long[MAX_N] labels = zeroed;
    for (usz v = 0; v < n; v += 1) labels[v] = (long)v;
    for (usz u = 0; u < n; u += 1) {
        usz[MAX_N] frequency = zeroed;
        usz degree = 0;
        for (usz v = 0; v < n; v += 1) {
            if (adjacent[u * MAX_N + v]) {
                frequency[(usz)labels[v]] += 1;
                degree += 1;
            }
        }
        if (degree == 0) continue;
        usz best_label = 0, best_frequency = 0;
        for (usz label = 0; label < n; label += 1) {
            if (frequency[label] > best_frequency ||
                (frequency[label] == best_frequency && frequency[label] != 0 && label > best_label)) {
                best_label = label;
                best_frequency = frequency[label];
            }
        }
        labels[u] = (long)best_label;
    }
    for (usz v = 0; v < n; v += 1) store_i64_le(output, 8 * v, labels[v]);
    return (long)output_bytes;
}
