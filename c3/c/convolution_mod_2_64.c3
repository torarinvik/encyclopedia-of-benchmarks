module convolution_mod_2_64;

const int MAX_LENGTH = 64;
const int MAX_NTT_SIZE = 128;
const int MAX_RESULT_LENGTH = 2 * MAX_LENGTH - 1;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_LENGTH + 1;
const long P0 = 998244353, P1 = 985661441, P2 = 943718401;
const long P3 = 935329793, P4 = 918552577;

fn long power_mod(long base, long exponent, long modulus) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

fn void transform(long* values, usz n, long modulus, long primitive_root, bool inverse) {
    for (usz i = 1, j = 0; i < n; i += 1) {
        usz bit = n >> 1;
        while ((j & bit) != 0) { j ^= bit; bit >>= 1; }
        j ^= bit;
        if (i < j) { long temporary = values[i]; values[i] = values[j]; values[j] = temporary; }
    }
    for (usz stage = 2; stage <= n; stage <<= 1) {
        long root = power_mod(primitive_root, (modulus - 1) / (long)stage, modulus);
        if (inverse) root = power_mod(root, modulus - 2, modulus);
        for (usz start = 0; start < n; start += stage) {
            long factor = 1;
            for (usz offset = 0; offset < stage / 2; offset += 1) {
                long left = values[start + offset];
                long right = values[start + offset + stage / 2] * factor % modulus;
                values[start + offset] = (left + right) % modulus;
                values[start + offset + stage / 2] = (left - right + modulus) % modulus;
                factor = factor * root % modulus;
            }
        }
    }
    if (inverse) {
        long scale = power_mod((long)n, modulus - 2, modulus);
        for (usz i = 0; i < n; i += 1) values[i] = values[i] * scale % modulus;
    }
}

fn void convolution_residues(long* input, usz n, usz m, usz transform_length,
                             long modulus, long primitive_root, long* result) {
    long[MAX_NTT_SIZE] a = zeroed, b = zeroed;
    for (usz i = 0; i < n; i += 1) a[i] = (long)((ulong)input[2 + i] % (ulong)modulus);
    for (usz i = 0; i < m; i += 1) b[i] = (long)((ulong)input[2 + n + i] % (ulong)modulus);
    transform(a, transform_length, modulus, primitive_root, false);
    transform(b, transform_length, modulus, primitive_root, false);
    for (usz i = 0; i < transform_length; i += 1) a[i] = a[i] * b[i] % modulus;
    transform(a, transform_length, modulus, primitive_root, true);
    for (usz i = 0; i < n + m - 1; i += 1) result[i] = a[i];
}

fn long positive_delta(long value, long partial, long modulus) {
    long delta = value - partial;
    if (delta < 0) delta += modulus;
    return delta;
}

fn void store_u64_le(usz offset, ulong value, byte* output) {
    for (int byte_index = 0; byte_index < 8; byte_index += 1) {
        output[offset + (usz)byte_index] = (byte)(value & 255);
        value >>= 8;
    }
}

fn long convolution_mod_2_64(long* input, usz length, byte* output, usz capacity)
    @export("convolution_mod_2_64") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > MAX_LENGTH || m_value < 1 || m_value > MAX_LENGTH) return -1;
    usz n = (usz)n_value, m = (usz)m_value;
    if (length != 2 + n + m) return -1;
    usz result_length = n + m - 1;
    usz transform_length = 1;
    while (transform_length < result_length) transform_length <<= 1;
    usz output_bytes = 8 * result_length;
    if (output == null || capacity < output_bytes) return -2;

    long[MAX_RESULT_LENGTH] r0 = zeroed, r1 = zeroed, r2 = zeroed, r3 = zeroed, r4 = zeroed;
    convolution_residues(input, n, m, transform_length, P0, 3, r0);
    convolution_residues(input, n, m, transform_length, P1, 3, r1);
    convolution_residues(input, n, m, transform_length, P2, 7, r2);
    convolution_residues(input, n, m, transform_length, P3, 3, r3);
    convolution_residues(input, n, m, transform_length, P4, 5, r4);

    long p01_p2 = (P0 % P2) * (P1 % P2) % P2;
    long p01_p3 = (P0 % P3) * (P1 % P3) % P3;
    long p01_p4 = (P0 % P4) * (P1 % P4) % P4;
    long p012_p3 = p01_p3 * (P2 % P3) % P3;
    long p012_p4 = p01_p4 * (P2 % P4) % P4;
    long p0123_p4 = p012_p4 * (P3 % P4) % P4;
    long inv0_p1 = power_mod(P0 % P1, P1 - 2, P1);
    long inv01_p2 = power_mod(p01_p2, P2 - 2, P2);
    long inv012_p3 = power_mod(p012_p3, P3 - 2, P3);
    long inv0123_p4 = power_mod(p0123_p4, P4 - 2, P4);
    for (usz i = 0; i < result_length; i += 1) {
        long t0 = r0[i];
        long t1 = positive_delta(r1[i], t0 % P1, P1) * inv0_p1 % P1;
        long x01_p2 = (r0[i] % P2 + (P0 % P2) * t1) % P2;
        long t2 = positive_delta(r2[i], x01_p2, P2) * inv01_p2 % P2;
        long x012_p3 = (r0[i] % P3 + (P0 % P3) * t1 + p01_p3 * t2) % P3;
        long t3 = positive_delta(r3[i], x012_p3, P3) * inv012_p3 % P3;
        long x0123_p4 = (r0[i] % P4 + (P0 % P4) * t1 + p01_p4 * t2 + p012_p4 * t3) % P4;
        long t4 = positive_delta(r4[i], x0123_p4, P4) * inv0123_p4 % P4;
        ulong value = (ulong)t0 + (ulong)P0 * (ulong)t1
            + (ulong)P0 * (ulong)P1 * (ulong)t2
            + (ulong)P0 * (ulong)P1 * (ulong)P2 * (ulong)t3
            + (ulong)P0 * (ulong)P1 * (ulong)P2 * (ulong)P3 * (ulong)t4;
        store_u64_le(8 * i, value, output);
    }
    return (long)output_bytes;
}
