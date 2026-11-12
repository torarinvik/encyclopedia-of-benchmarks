module gcd_convolution;

const int MAX_N = 128;
const usz MAX_INPUT_LENGTH = 1 + 2 * MAX_N + 1;
const long MODULUS = 998244353;

fn void store_i64_le(usz offset, long value, byte* output) {
    ulong bits = (ulong)value;
    for (int byte_index = 0; byte_index < 8; byte_index += 1) {
        output[offset + (usz)byte_index] = (byte)(bits & 255);
        bits >>= 8;
    }
}

fn void divisor_zeta(long* values, int n) {
    for (int divisor = 1; divisor <= n; divisor += 1)
        for (int multiple = 2 * divisor; multiple <= n; multiple += divisor) {
            values[divisor] += values[multiple];
            if (values[divisor] >= MODULUS) values[divisor] -= MODULUS;
        }
}

fn void divisor_mobius(long* values, int n) {
    for (int divisor = n; divisor >= 1; divisor -= 1)
        for (int multiple = 2 * divisor; multiple <= n; multiple += divisor) {
            values[divisor] -= values[multiple];
            if (values[divisor] < 0) values[divisor] += MODULUS;
        }
}

fn long gcd_convolution(long* input, usz length, byte* output, usz capacity)
    @export("gcd_convolution") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > MAX_N) return -1;
    int n = (int)n_value;
    if (length != (usz)(1 + 2 * n)) return -1;
    for (int index = 0; index < 2 * n; index += 1)
        if (input[1 + index] < 0 || input[1 + index] >= MODULUS) return -1;

    usz output_bytes = 8 * (usz)n;
    if (output == null || capacity < output_bytes) return -2;
    long[MAX_N + 1] a = zeroed, b = zeroed, c = zeroed;
    for (int index = 1; index <= n; index += 1) {
        a[index] = input[index];
        b[index] = input[n + index];
    }
    divisor_zeta(a, n);
    divisor_zeta(b, n);
    for (int index = 1; index <= n; index += 1)
        c[index] = (a[index] * b[index]) % MODULUS;
    divisor_mobius(c, n);
    for (int index = 1; index <= n; index += 1)
        store_i64_le(8 * (usz)(index - 1), c[index], output);
    return (long)output_bytes;
}
