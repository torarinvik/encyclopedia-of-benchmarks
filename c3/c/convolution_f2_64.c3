module convolution_f2_64;

const int MAX_N = 8, MAX_M = 8, MAX_PARSEABLE = 19;

fn ulong multiply_in_field(ulong left, ulong right) {
    ulong result = 0, shifted = left, multiplier = right;
    for (int bit = 0; bit < 64; bit++) {
        if ((multiplier & 1u64) != 0) result ^= shifted;
        bool carry = (shifted >> 63) != 0;
        shifted <<= 1;
        if (carry) shifted ^= 0x1bu64;
        multiplier >>= 1;
    }
    return result;
}

fn long convolution_f2_64(long* input, usz length, uchar* output, usz output_capacity)
    @export("convolution_f2_64") {
    if (input == null || length < 2 || length > MAX_PARSEABLE) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_M) return -1;
    int n = (int)input[0], m = (int)input[1];
    if (length != 2 + n + m) return -1;
    usz count = (usz)(n + m - 1), needed = 8 * count;
    if (output == null || output_capacity < needed) return -2;

    ulong[MAX_N] a = {}, b = {};
    ulong[MAX_N + MAX_M - 1] product = {};
    for (int i = 0; i < n; i++) a[i] = (ulong)input[2 + i];
    for (int j = 0; j < m; j++) b[j] = (ulong)input[2 + n + j];
    for (int i = 0; i < n; i++)
        for (int j = 0; j < m; j++) product[i + j] ^= multiply_in_field(a[i], b[j]);
    for (usz i = 0; i < count; i++) {
        ulong bits = product[i];
        for (int byte = 0; byte < 8; byte++) {
            output[8 * i + (usz)byte] = (uchar)(bits & 255u64);
            bits >>= 8;
        }
    }
    return (long)needed;
}
