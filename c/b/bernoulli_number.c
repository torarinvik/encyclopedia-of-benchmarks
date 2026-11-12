#include <stddef.h>
#include <stdint.h>

#define MODULUS INT64_C(998244353)
#define MAX_N 32
#define MAX_OUTPUT_BYTES (4 * (MAX_N + 1))

static int64_t modular_power(int64_t base, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

int64_t bernoulli_number(const int64_t *input, size_t length,
                         uint8_t *output, size_t capacity) {
    if (input == NULL || length != 1) return -1;
    const int64_t n64 = input[0];
    if (n64 < 0 || n64 > MAX_N) return -1;
    const size_t n = (size_t)n64;
    const size_t output_bytes = 4 * (n + 1);
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t inverse[MAX_N + 2] = {0};
    int64_t bernoulli[MAX_N + 1] = {0};
    inverse[1] = 1;
    for (size_t i = 2; i <= n + 1; ++i) {
        inverse[i] = modular_power((int64_t)i, MODULUS - 2);
    }

    bernoulli[0] = 1;
    for (size_t m = 1; m <= n; ++m) {
        int64_t choose = 1;
        int64_t sum = 0;
        for (size_t k = 0; k < m; ++k) {
            sum = (sum + choose * bernoulli[k]) % MODULUS;
            choose = choose * (int64_t)(m + 1 - k) % MODULUS *
                inverse[k + 1] % MODULUS;
        }
        bernoulli[m] = ((MODULUS - sum) % MODULUS) * inverse[m + 1] % MODULUS;
    }

    for (size_t i = 0; i <= n; ++i) {
        const uint32_t value = (uint32_t)bernoulli[i];
        output[4 * i] = (uint8_t)value;
        output[4 * i + 1] = (uint8_t)(value >> 8);
        output[4 * i + 2] = (uint8_t)(value >> 16);
        output[4 * i + 3] = (uint8_t)(value >> 24);
    }
    return (int64_t)output_bytes;
}
