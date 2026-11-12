module convolution_mod_1000000007;

const usz MAX_LENGTH = 64;
const usz NTT_SIZE = 128;
const usz MAX_RESULT = 2 * MAX_LENGTH - 1;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_LENGTH;
const long MODULUS = 1000000007;
const long P1 = 998244353;
const long P2 = 1004535809;
const long P3 = 469762049;

fn long power_mod(long base, long exponent, long modulus) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

fn void transform(long* values, usz n, long modulus, bool inverse) {
    usz j = 0;
    for (usz i = 1; i < n; i += 1) {
        usz bit = n >> 1;
        while ((j & bit) != 0) { j ^= bit; bit >>= 1; }
        j ^= bit;
        if (i < j) { long temporary = values[i]; values[i] = values[j]; values[j] = temporary; }
    }
    for (usz stage = 2; stage <= n; stage *= 2) {
        long root = power_mod(3, (modulus - 1) / (long)stage, modulus);
        if (inverse) root = power_mod(root, modulus - 2, modulus);
        for (usz start = 0; start < n; start += stage) {
            long factor = 1;
            for (usz offset = 0; offset < stage / 2; offset += 1) {
                long left = values[start + offset];
                long right = (values[start + offset + stage / 2] * factor) % modulus;
                values[start + offset] = (left + right) % modulus;
                values[start + offset + stage / 2] = (left - right + modulus) % modulus;
                factor = (factor * root) % modulus;
            }
        }
    }
    if (inverse) {
        long scale = power_mod((long)n, modulus - 2, modulus);
        for (usz i = 0; i < n; i += 1) values[i] = (values[i] * scale) % modulus;
    }
}

fn void convolution_residues(long* input, usz n, usz m, usz transform_length,
    usz result_length, long modulus, long* result) {
    long[NTT_SIZE] a;
    long[NTT_SIZE] b;
    for (usz i = 0; i < NTT_SIZE; i += 1) { a[i] = 0; b[i] = 0; }
    for (usz i = 0; i < n; i += 1) a[i] = input[2 + i] % modulus;
    for (usz i = 0; i < m; i += 1) b[i] = input[2 + n + i] % modulus;
    transform(&a[0], transform_length, modulus, false);
    transform(&b[0], transform_length, modulus, false);
    for (usz i = 0; i < transform_length; i += 1) a[i] = (a[i] * b[i]) % modulus;
    transform(&a[0], transform_length, modulus, true);
    for (usz i = 0; i < result_length; i += 1) result[i] = a[i];
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long convolution_mod_1000000007(long* input, usz length, char* output, usz capacity)
    @export("convolution_mod_1000000007") {
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

    long[MAX_RESULT] r1;
    long[MAX_RESULT] r2;
    long[MAX_RESULT] r3;
    convolution_residues(input, n, m, transform_length, result_length, P1, &r1[0]);
    convolution_residues(input, n, m, transform_length, result_length, P2, &r2[0]);
    convolution_residues(input, n, m, transform_length, result_length, P3, &r3[0]);
    long inv1 = power_mod(P1 % P2, P2 - 2, P2);
    long p12mod3 = (P1 % P3) * (P2 % P3) % P3;
    long inv12 = power_mod(p12mod3, P3 - 2, P3);
    long p1mod = P1 % MODULUS;
    long p12mod = p1mod * (P2 % MODULUS) % MODULUS;
    for (usz i = 0; i < result_length; i += 1) {
        long t1 = ((r2[i] - r1[i] % P2 + P2) % P2) * inv1 % P2;
        long x12 = (r1[i] % P3 + (P1 % P3) * (t1 % P3)) % P3;
        long t2 = ((r3[i] - x12 + P3) % P3) * inv12 % P3;
        long value = (r1[i] + p1mod * (t1 % MODULUS) + p12mod * (t2 % MODULUS)) % MODULUS;
        store_i64_le(output, 8 * i, value);
    }
    return (long)output_bytes;
}
