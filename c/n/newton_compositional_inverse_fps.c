#include <stddef.h>
#include <stdint.h>

#define MOD INT64_C(998244353)
#define LIMIT 16

static int64_t power_mod(int64_t value, int64_t exponent) {
    int64_t result = 1;
    while (exponent) {
        if (exponent & 1) result = result * value % MOD;
        value = value * value % MOD;
        exponent >>= 1;
    }
    return result;
}

/* Horner composition, truncated after every multiplication. */
static void compose(const int64_t *outer, size_t outer_length,
                    const int64_t *inner, size_t width, int64_t *result) {
    int64_t next[LIMIT];
    for (size_t i = 0; i < width; ++i) result[i] = 0;
    for (size_t degree = outer_length; degree-- > 0;) {
        for (size_t i = 0; i < width; ++i) next[i] = 0;
        for (size_t i = 0; i < width; ++i)
            for (size_t j = 0; i + j < width; ++j)
                next[i + j] = (next[i + j] + result[i] * inner[j]) % MOD;
        next[0] = (next[0] + outer[degree]) % MOD;
        for (size_t i = 0; i < width; ++i) result[i] = next[i];
    }
}

int64_t newton_compositional_inverse_fps(const int64_t *input, size_t length,
                                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > 18) return -1;
    if (input[0] < 2 || input[0] > LIMIT) return -1;
    size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= MOD) return -1;
    if (input[1] != 0 || input[2] == 0) return -1;
    size_t bytes = n * 8;
    if (output == NULL || capacity < bytes) return -2;

    int64_t f[LIMIT] = {0}, derivative[LIMIT] = {0}, inverse[LIMIT] = {0};
    int64_t residual[LIMIT], slope[LIMIT], reciprocal[LIMIT], correction[LIMIT];
    for (size_t i = 0; i < n; ++i) f[i] = input[i + 1];
    for (size_t i = 1; i < n; ++i) derivative[i - 1] = (int64_t)i * f[i] % MOD;
    int64_t linear_inverse = power_mod(f[1], MOD - 2);
    inverse[1] = linear_inverse;
    size_t precision = 2;
    while (precision < n) {
        size_t width = precision * 2 < n ? precision * 2 : n;
        compose(f, width, inverse, width, residual);
        residual[1] = (residual[1] + MOD - 1) % MOD;
        compose(derivative, width - 1, inverse, width, slope);
        reciprocal[0] = linear_inverse;
        for (size_t i = 1; i < width; ++i) {
            int64_t sum = 0;
            for (size_t j = 1; j <= i; ++j)
                sum = (sum + slope[j] * reciprocal[i - j]) % MOD;
            reciprocal[i] = (MOD - sum) * linear_inverse % MOD;
        }
        for (size_t i = 0; i < width; ++i) {
            correction[i] = 0;
            for (size_t j = 0; j <= i; ++j)
                correction[i] = (correction[i] + residual[j] * reciprocal[i - j]) % MOD;
        }
        for (size_t i = 0; i < width; ++i)
            inverse[i] = (inverse[i] + MOD - correction[i]) % MOD;
        precision = width;
    }
    for (size_t i = 0; i < n; ++i) {
        uint64_t bits = (uint64_t)inverse[i];
        for (size_t byte = 0; byte < 8; ++byte) {
            output[8 * i + byte] = (uint8_t)(bits & 255);
            bits >>= 8;
        }
    }
    return (int64_t)bytes;
}
