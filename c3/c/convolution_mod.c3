module convolution_mod;

const usz MAX_LENGTH = 256;
const usz MAX_NTT_SIZE = 512;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_LENGTH;
const long MODULUS = 998244353;

fn long power_mod(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % MODULUS;
        base = (base * base) % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn void transform(long* values, usz n, bool inverse) {
    usz j = 0;
    for (usz i = 1; i < n; i += 1) {
        usz bit = n >> 1;
        while ((j & bit) != 0) { j ^= bit; bit >>= 1; }
        j ^= bit;
        if (i < j) { long temporary = values[i]; values[i] = values[j]; values[j] = temporary; }
    }
    for (usz stage = 2; stage <= n; stage *= 2) {
        long root = power_mod(3, (MODULUS - 1) / (long)stage);
        if (inverse) root = power_mod(root, MODULUS - 2);
        for (usz start = 0; start < n; start += stage) {
            long factor = 1;
            for (usz offset = 0; offset < stage / 2; offset += 1) {
                long left = values[start + offset];
                long right = (values[start + offset + stage / 2] * factor) % MODULUS;
                values[start + offset] = (left + right) % MODULUS;
                values[start + offset + stage / 2] = (left - right + MODULUS) % MODULUS;
                factor = (factor * root) % MODULUS;
            }
        }
    }
    if (inverse) {
        long scale = power_mod((long)n, MODULUS - 2);
        for (usz i = 0; i < n; i += 1) values[i] = (values[i] * scale) % MODULUS;
    }
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long convolution_mod(long* input, usz length, char* output, usz capacity)
    @export("convolution_mod") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0];
    long m_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_LENGTH || m_value < 1 || m_value > (long)MAX_LENGTH) return -1;
    usz n = (usz)n_value;
    usz m = (usz)m_value;
    if (length != 2 + n + m) return -1;
    for (usz i = 0; i < n + m; i += 1)
        if (input[2 + i] < 0 || input[2 + i] >= MODULUS) return -1;

    usz result_length = n + m - 1;
    usz transform_length = 1;
    while (transform_length < result_length) transform_length *= 2;
    usz output_bytes = 8 * result_length;
    if (output == null || capacity < output_bytes) return -2;

    long[MAX_NTT_SIZE] a;
    long[MAX_NTT_SIZE] b;
    for (usz i = 0; i < MAX_NTT_SIZE; i += 1) { a[i] = 0; b[i] = 0; }
    for (usz i = 0; i < n; i += 1) a[i] = input[2 + i];
    for (usz i = 0; i < m; i += 1) b[i] = input[2 + n + i];
    transform(&a[0], transform_length, false);
    transform(&b[0], transform_length, false);
    for (usz i = 0; i < transform_length; i += 1) a[i] = (a[i] * b[i]) % MODULUS;
    transform(&a[0], transform_length, true);
    for (usz i = 0; i < result_length; i += 1) store_i64_le(output, 8 * i, a[i]);
    return (long)output_bytes;
}
