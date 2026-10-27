module min_plus_distance_product;

const int MAX_INPUT = 130;
const usz MAX_OUTPUT = 512;
const usz MAX_DIM = 8;
const long INF = 1000000;

fn void store_i64_le(uint8 *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (uint8)(bits & 255ul); bits >>= 8; }
}

fn long min_plus_distance_product(long *input, usz length, uint8 *output, usz capacity)
    @export("min_plus_distance_product") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > MAX_DIM || m0 < 1 || m0 > MAX_DIM) return -1;
    usz n = (usz)n0, m = (usz)m0;
    if (length != 2 + 2 * n * m) return -1;
    for (usz i = 2; i < length; i++)
        if (input[i] < 0 || (input[i] > 1000 && input[i] != INF)) return -1;
    usz bytes = 8 * n * n;
    if (bytes > MAX_OUTPUT) return -1;
    if (output == null || capacity < bytes) return -2;
    long[MAX_DIM * MAX_DIM] result;
    long *a = input + 2;
    long *b = input + 2 + n * m;
    for (usz i = 0; i < n; i++) {
        for (usz j = 0; j < n; j++) {
            long best = INF;
            for (usz k = 0; k < m; k++) {
                long x = a[i * m + k], y = b[k * n + j];
                if (x != INF && y != INF && x + y < best) best = x + y;
            }
            result[i * n + j] = best;
        }
    }
    for (usz i = 0; i < n * n; i++) store_i64_le(output, 8 * i, result[i]);
    return (long)bytes;
}
