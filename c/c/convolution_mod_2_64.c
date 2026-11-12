#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 64
#define MAX_NTT_SIZE 128
#define MAX_INPUT_LENGTH (2 + 2 * MAX_LENGTH + 1)
#define MAX_RESULT_LENGTH (2 * MAX_LENGTH - 1)

static const int64_t moduli[5] = {
    INT64_C(998244353), INT64_C(985661441), INT64_C(943718401),
    INT64_C(935329793), INT64_C(918552577)
};
static const int64_t roots[5] = {3, 3, 7, 3, 5};

static int64_t power_mod(int64_t base, int64_t exponent, int64_t modulus) {
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

static void transform(int64_t *values, size_t n, int64_t modulus,
                      int64_t primitive_root, int inverse) {
    for (size_t i = 1, j = 0; i < n; ++i) {
        size_t bit = n >> 1;
        for (; (j & bit) != 0; bit >>= 1) j ^= bit;
        j ^= bit;
        if (i < j) {
            const int64_t temporary = values[i];
            values[i] = values[j];
            values[j] = temporary;
        }
    }
    for (size_t stage = 2; stage <= n; stage <<= 1) {
        int64_t root = power_mod(primitive_root, (modulus - 1) / (int64_t)stage, modulus);
        if (inverse) root = power_mod(root, modulus - 2, modulus);
        for (size_t start = 0; start < n; start += stage) {
            int64_t factor = 1;
            for (size_t offset = 0; offset < stage / 2; ++offset) {
                const int64_t left = values[start + offset];
                const int64_t right = (values[start + offset + stage / 2] * factor) % modulus;
                values[start + offset] = (left + right) % modulus;
                values[start + offset + stage / 2] = (left - right + modulus) % modulus;
                factor = (factor * root) % modulus;
            }
        }
    }
    if (inverse) {
        const int64_t scale = power_mod((int64_t)n, modulus - 2, modulus);
        for (size_t i = 0; i < n; ++i) values[i] = (values[i] * scale) % modulus;
    }
}

static void convolution_residues(const int64_t *input, size_t n, size_t m,
                                 size_t transform_length, int64_t modulus,
                                 int64_t primitive_root, int64_t *result) {
    int64_t a[MAX_NTT_SIZE] = {0};
    int64_t b[MAX_NTT_SIZE] = {0};
    for (size_t i = 0; i < n; ++i)
        a[i] = (int64_t)(((uint64_t)input[2 + i]) % (uint64_t)modulus);
    for (size_t i = 0; i < m; ++i)
        b[i] = (int64_t)(((uint64_t)input[2 + n + i]) % (uint64_t)modulus);
    transform(a, transform_length, modulus, primitive_root, 0);
    transform(b, transform_length, modulus, primitive_root, 0);
    for (size_t i = 0; i < transform_length; ++i) a[i] = (a[i] * b[i]) % modulus;
    transform(a, transform_length, modulus, primitive_root, 1);
    for (size_t i = 0; i < n + m - 1; ++i) result[i] = a[i];
}

static int64_t positive_delta(int64_t value, int64_t partial, int64_t modulus) {
    int64_t delta = value - partial;
    if (delta < 0) delta += modulus;
    return delta;
}

static void store_u64_le(uint8_t *output, size_t offset, uint64_t value) {
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(value >> (8 * byte));
}

int64_t convolution_mod_2_64(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > MAX_LENGTH || m_value < 1 || m_value > MAX_LENGTH) return -1;
    const size_t n = (size_t)n_value, m = (size_t)m_value;
    if (length != 2 + n + m) return -1;

    const size_t result_length = n + m - 1;
    size_t transform_length = 1;
    while (transform_length < result_length) transform_length <<= 1;
    const size_t output_bytes = 8 * result_length;
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t residues[5][MAX_RESULT_LENGTH];
    for (size_t index = 0; index < 5; ++index)
        convolution_residues(input, n, m, transform_length,
                             moduli[index], roots[index], residues[index]);

    const int64_t p0 = moduli[0], p1 = moduli[1], p2 = moduli[2];
    const int64_t p3 = moduli[3], p4 = moduli[4];
    const int64_t p01_mod_p2 = (p0 % p2) * (p1 % p2) % p2;
    const int64_t p01_mod_p3 = (p0 % p3) * (p1 % p3) % p3;
    const int64_t p01_mod_p4 = (p0 % p4) * (p1 % p4) % p4;
    const int64_t p012_mod_p3 = p01_mod_p3 * (p2 % p3) % p3;
    const int64_t p012_mod_p4 = p01_mod_p4 * (p2 % p4) % p4;
    const int64_t p0123_mod_p4 = p012_mod_p4 * (p3 % p4) % p4;
    const int64_t inv_p0_p1 = power_mod(p0 % p1, p1 - 2, p1);
    const int64_t inv_p01_p2 = power_mod(p01_mod_p2, p2 - 2, p2);
    const int64_t inv_p012_p3 = power_mod(p012_mod_p3, p3 - 2, p3);
    const int64_t inv_p0123_p4 = power_mod(p0123_mod_p4, p4 - 2, p4);

    for (size_t index = 0; index < result_length; ++index) {
        const int64_t t0 = residues[0][index];
        const int64_t t1 = positive_delta(residues[1][index], t0 % p1, p1)
                           * inv_p0_p1 % p1;
        const int64_t x01_p2 = (residues[0][index] % p2 + (p0 % p2) * t1) % p2;
        const int64_t t2 = positive_delta(residues[2][index], x01_p2, p2)
                           * inv_p01_p2 % p2;
        const int64_t x012_p3 = (residues[0][index] % p3 + (p0 % p3) * t1
                                 + p01_mod_p3 * t2) % p3;
        const int64_t t3 = positive_delta(residues[3][index], x012_p3, p3)
                           * inv_p012_p3 % p3;
        const int64_t x0123_p4 = (residues[0][index] % p4 + (p0 % p4) * t1
                                  + p01_mod_p4 * t2
                                  + p012_mod_p4 * t3) % p4;
        const int64_t t4 = positive_delta(residues[4][index], x0123_p4, p4)
                           * inv_p0123_p4 % p4;
        const uint64_t value = (uint64_t)t0 + (uint64_t)p0 * (uint64_t)t1
            + (uint64_t)p0 * (uint64_t)p1 * (uint64_t)t2
            + (uint64_t)p0 * (uint64_t)p1 * (uint64_t)p2 * (uint64_t)t3
            + (uint64_t)p0 * (uint64_t)p1 * (uint64_t)p2 * (uint64_t)p3 * (uint64_t)t4;
        store_u64_le(output, 8 * index, value);
    }
    return (int64_t)output_bytes;
}
