#include <stddef.h>
#include <stdint.h>

#define MAX_N 128
#define MAX_INPUT_LENGTH (1 + 2 * MAX_N + 1)
#define MODULUS INT64_C(998244353)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static void multiple_zeta(int64_t *values, int n) {
    for (int divisor = n; divisor >= 1; --divisor)
        for (int multiple = 2 * divisor; multiple <= n; multiple += divisor) {
            values[multiple] += values[divisor];
            if (values[multiple] >= MODULUS) values[multiple] -= MODULUS;
        }
}

static void multiple_mobius(int64_t *values, int n) {
    for (int divisor = 1; divisor <= n; ++divisor)
        for (int multiple = 2 * divisor; multiple <= n; multiple += divisor) {
            values[multiple] -= values[divisor];
            if (values[multiple] < 0) values[multiple] += MODULUS;
        }
}

int64_t lcm_convolution(const int64_t *input, size_t length,
                        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N) return -1;
    const int n = (int)n_value;
    if (length != (size_t)(1 + 2 * n)) return -1;
    for (int index = 0; index < 2 * n; ++index)
        if (input[1 + index] < 0 || input[1 + index] >= MODULUS) return -1;

    const size_t output_bytes = 8u * (size_t)n;
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t a[MAX_N + 1] = {0};
    int64_t b[MAX_N + 1] = {0};
    int64_t c[MAX_N + 1] = {0};
    for (int index = 1; index <= n; ++index) {
        a[index] = input[index];
        b[index] = input[n + index];
    }
    multiple_zeta(a, n);
    multiple_zeta(b, n);
    for (int index = 1; index <= n; ++index)
        c[index] = (a[index] * b[index]) % MODULUS;
    multiple_mobius(c, n);
    for (int index = 1; index <= n; ++index)
        store_i64_le(output, 8u * (size_t)(index - 1), c[index]);
    return (int64_t)output_bytes;
}
