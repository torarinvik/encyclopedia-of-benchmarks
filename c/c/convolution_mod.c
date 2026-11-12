#include <stddef.h>
#include <stdint.h>

#define MODULUS INT64_C(998244353)
#define MAX_LENGTH 256
#define MAX_NTT_SIZE 512
#define MAX_INPUT_LENGTH (2u + 2u * MAX_LENGTH)

static int64_t power_mod(int64_t base, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % MODULUS;
        base = (base * base) % MODULUS;
        exponent >>= 1;
    }
    return result;
}

static void transform(int64_t *values, size_t n, int inverse) {
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
        int64_t root = power_mod(3, (MODULUS - 1) / (int64_t)stage);
        if (inverse) root = power_mod(root, MODULUS - 2);
        for (size_t start = 0; start < n; start += stage) {
            int64_t factor = 1;
            for (size_t offset = 0; offset < stage / 2; ++offset) {
                const int64_t left = values[start + offset];
                const int64_t right = (values[start + offset + stage / 2] * factor) % MODULUS;
                values[start + offset] = (left + right) % MODULUS;
                values[start + offset + stage / 2] = (left - right + MODULUS) % MODULUS;
                factor = (factor * root) % MODULUS;
            }
        }
    }
    if (inverse) {
        const int64_t scale = power_mod((int64_t)n, MODULUS - 2);
        for (size_t i = 0; i < n; ++i) values[i] = (values[i] * scale) % MODULUS;
    }
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t convolution_mod(const int64_t *input, size_t length,
                        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    const int64_t m_value = input[1];
    if (n_value < 1 || n_value > MAX_LENGTH || m_value < 1 || m_value > MAX_LENGTH)
        return -1;
    const size_t n = (size_t)n_value;
    const size_t m = (size_t)m_value;
    if (length != 2 + n + m) return -1;
    for (size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] >= MODULUS) return -1;

    const size_t result_length = n + m - 1;
    size_t transform_length = 1;
    while (transform_length < result_length) transform_length <<= 1;
    const size_t output_bytes = 8 * result_length;
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t a[MAX_NTT_SIZE] = {0};
    int64_t b[MAX_NTT_SIZE] = {0};
    for (size_t i = 0; i < n; ++i) a[i] = input[2 + i];
    for (size_t i = 0; i < m; ++i) b[i] = input[2 + n + i];
    transform(a, transform_length, 0);
    transform(b, transform_length, 0);
    for (size_t i = 0; i < transform_length; ++i) a[i] = (a[i] * b[i]) % MODULUS;
    transform(a, transform_length, 1);
    for (size_t i = 0; i < result_length; ++i) store_i64_le(output, 8 * i, a[i]);
    return (int64_t)output_bytes;
}
