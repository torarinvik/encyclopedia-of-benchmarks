#include <stddef.h>
#include <stdint.h>

#define MODULUS INT64_C(1000000007)
#define P1 INT64_C(998244353)
#define P2 INT64_C(1004535809)
#define P3 INT64_C(469762049)
#define MAX_LENGTH 64
#define MAX_NTT_SIZE 128
#define MAX_INPUT_LENGTH (2u + 2u * MAX_LENGTH)
#define MAX_RESULT_LENGTH (2u * MAX_LENGTH - 1u)

static int64_t power_mod(int64_t base, int64_t exponent, int64_t modulus) {
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

static void transform(int64_t *values, size_t n, int64_t modulus, int inverse) {
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
        int64_t root = power_mod(3, (modulus - 1) / (int64_t)stage, modulus);
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
                                 size_t transform_length, size_t result_length,
                                 int64_t modulus, int64_t *result) {
    int64_t a[MAX_NTT_SIZE] = {0};
    int64_t b[MAX_NTT_SIZE] = {0};
    for (size_t i = 0; i < n; ++i) a[i] = input[2 + i] % modulus;
    for (size_t i = 0; i < m; ++i) b[i] = input[2 + n + i] % modulus;
    transform(a, transform_length, modulus, 0);
    transform(b, transform_length, modulus, 0);
    for (size_t i = 0; i < transform_length; ++i) a[i] = (a[i] * b[i]) % modulus;
    transform(a, transform_length, modulus, 1);
    for (size_t i = 0; i < result_length; ++i) result[i] = a[i];
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t convolution_mod_1000000007(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    const int64_t m_value = input[1];
    if (n_value < 1 || n_value > MAX_LENGTH || m_value < 1 || m_value > MAX_LENGTH) return -1;
    const size_t n = (size_t)n_value, m = (size_t)m_value;
    if (length != 2 + n + m) return -1;
    for (size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] >= MODULUS) return -1;

    const size_t result_length = n + m - 1;
    size_t transform_length = 1;
    while (transform_length < result_length) transform_length <<= 1;
    const size_t output_bytes = 8 * result_length;
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t r1[MAX_RESULT_LENGTH], r2[MAX_RESULT_LENGTH], r3[MAX_RESULT_LENGTH];
    convolution_residues(input, n, m, transform_length, result_length, P1, r1);
    convolution_residues(input, n, m, transform_length, result_length, P2, r2);
    convolution_residues(input, n, m, transform_length, result_length, P3, r3);
    const int64_t inv_p1_p2 = power_mod(P1 % P2, P2 - 2, P2);
    const int64_t p1p2_mod_p3 = (P1 % P3) * (P2 % P3) % P3;
    const int64_t inv_p1p2_p3 = power_mod(p1p2_mod_p3, P3 - 2, P3);
    const int64_t p1_mod_target = P1 % MODULUS;
    const int64_t p1p2_mod_target = (P1 % MODULUS) * (P2 % MODULUS) % MODULUS;
    for (size_t i = 0; i < result_length; ++i) {
        const int64_t delta1 = (r2[i] - r1[i] % P2 + P2) % P2;
        const int64_t t1 = delta1 * inv_p1_p2 % P2;
        const int64_t x12_mod_p3 = (r1[i] % P3 + (P1 % P3) * (t1 % P3)) % P3;
        const int64_t delta2 = (r3[i] - x12_mod_p3 + P3) % P3;
        const int64_t t2 = delta2 * inv_p1p2_p3 % P3;
        const int64_t value = (r1[i] + p1_mod_target * (t1 % MODULUS)
                               + p1p2_mod_target * (t2 % MODULUS)) % MODULUS;
        store_i64_le(output, 8 * i, value);
    }
    return (int64_t)output_bytes;
}
