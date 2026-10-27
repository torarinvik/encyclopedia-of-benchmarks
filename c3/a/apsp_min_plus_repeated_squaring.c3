module apsp_min_plus_repeated_squaring;

const int MAX_N = 8;
const long INF = 1000000;

fn void store_i64_le(uint8 *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255ul);
        bits >>= 8;
    }
}

fn long apsp_min_plus_repeated_squaring(long *input, usz length, uint8 *output, usz capacity)
    @export("apsp_min_plus_repeated_squaring") {
    if (input == null || length < 2 || length > 65) return -1;
    long n0 = input[0];
    if (n0 < 1 || n0 > MAX_N) return -1;
    usz n = (usz)n0;
    if (length != 1 + n * n) return -1;
    long[MAX_N * MAX_N] current;
    long[MAX_N * MAX_N] next;
    for (usz i = 0; i < n; i++) {
        for (usz j = 0; j < n; j++) {
            long value = input[1 + i * n + j];
            if ((i == j && value != 0) ||
                (i != j && value != INF && (value < 1 || value > 1000))) return -1;
            current[i * n + j] = value;
        }
    }
    usz edge_bound = 1;
    while (edge_bound < n - 1) {
        for (usz i = 0; i < n; i++) {
            for (usz j = 0; j < n; j++) {
                long best = INF;
                for (usz k = 0; k < n; k++) {
                    long left = current[i * n + k], right = current[k * n + j];
                    if (left != INF && right != INF && left + right < best) best = left + right;
                }
                next[i * n + j] = best;
            }
        }
        for (usz i = 0; i < n * n; i++) current[i] = next[i];
        edge_bound *= 2;
    }
    usz bytes = 8 * n * n;
    if (output == null || capacity < bytes) return -2;
    for (usz i = 0; i < n * n; i++) store_i64_le(output, 8 * i, current[i]);
    return (long)bytes;
}
