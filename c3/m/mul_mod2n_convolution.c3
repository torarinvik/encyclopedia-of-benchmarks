module mul_mod2n_convolution;

const usz MAX_N = 5;
const usz MAX_P = 32;
const usz MAX_INPUT = 66;
const usz MAX_OUTPUT = 256;
const long MOD = 998244353;

fn void store_le(uint8 *out, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { out[offset + byte] = (uint8)(bits & 255ul); bits >>= 8; }
}

fn long mul_mod2n_convolution(long *input, usz length, uint8 *output, usz capacity)
    @export("mul_mod2n_convolution") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n0 = input[0];
    if (n0 < 0 || n0 > 5) return -1;
    usz p = (usz)1 << (usz)n0;
    if (length != 1 + 2 * p) return -1;
    for (usz i = 1; i < length; i++) if (input[i] < 0 || input[i] >= MOD) return -1;
    usz bytes = 8 * p;
    if (bytes > MAX_OUTPUT) return -1;
    if (output == null || capacity < bytes) return -2;
    long[MAX_P] a, b, result;
    for (usz i = 0; i < p; i++) { a[i] = input[1 + i]; b[i] = input[1 + p + i]; result[i] = 0; }
    usz mask = p - 1;
    for (usz i = 0; i < p; i++) for (usz j = 0; j < p; j++) {
        usz k = (i * j) & mask;
        result[k] = (result[k] + a[i] * b[j]) % MOD;
    }
    for (usz i = 0; i < p; i++) store_le(output, 8 * i, result[i]);
    return (long)bytes;
}
