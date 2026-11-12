module min_plus_convolution_convex_convex;

const int MAX_INPUT = 259;
const usz MAX_OUTPUT = 2040;
const usz MAX_N = 128;
const usz MAX_M = 128;

fn void store_i64_le(uint8 *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255ul);
        bits >>= 8;
    }
}

fn bool is_convex(long *values, usz length) {
    for (usz i = 0; i + 2 < length; i++)
        if (values[i + 1] - values[i] > values[i + 2] - values[i + 1]) return false;
    return true;
}

fn long min_plus_convolution_convex_convex(long *input, usz length, uint8 *output, usz capacity)
    @export("min_plus_convolution_convex_convex") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > 128 || m0 < 1 || m0 > 128) return -1;
    usz n = (usz)n0, m = (usz)m0;
    if (length != 2 + n + m) return -1;
    long *a = input + 2, *b = input + 2 + n;
    for (usz i = 0; i < n + m; i++)
        if (input[2 + i] < 0 || input[2 + i] > 1000000000) return -1;
    if (!is_convex(a, n) || !is_convex(b, m)) return -1;

    usz count = n + m - 1, bytes = 8 * count;
    if (bytes > MAX_OUTPUT) return -1;
    if (output == null || capacity < bytes) return -2;

    long[MAX_N + MAX_M - 1] result;
    result[0] = a[0] + b[0];
    usz ai = 0, bi = 0, out = 1;
    while (ai + 1 < n || bi + 1 < m) {
        long slope;
        if (bi + 1 == m || (ai + 1 < n && a[ai + 1] - a[ai] <= b[bi + 1] - b[bi])) {
            slope = a[ai + 1] - a[ai];
            ai++;
        } else {
            slope = b[bi + 1] - b[bi];
            bi++;
        }
        result[out] = result[out - 1] + slope;
        out++;
    }
    for (usz i = 0; i < count; i++) store_i64_le(output, 8 * i, result[i]);
    return (long)bytes;
}
