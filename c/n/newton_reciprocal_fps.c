#include <stddef.h>
#include <stdint.h>

#define MOD INT64_C(998244353)
#define LIMIT 64

static int64_t power_mod(int64_t base, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % MOD;
        base = base * base % MOD;
        exponent >>= 1;
    }
    return result;
}

int64_t newton_reciprocal_fps(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 66) return -1;
    if (input[0] < 1 || input[0] > LIMIT) return -1;
    size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= MOD) return -1;
    if (input[1] == 0) return -1;
    size_t bytes = 8 * n;
    if (output == NULL || capacity < bytes) return -2;
    int64_t inverse[LIMIT] = {0}, product[LIMIT], next[LIMIT];
    inverse[0] = power_mod(input[1], MOD - 2);
    size_t precision = 1;
    while (precision < n) {
        size_t width = precision * 2 < n ? precision * 2 : n;
        for (size_t i = 0; i < width; ++i) product[i] = 0;
        for (size_t i = 0; i < width; ++i)
            for (size_t j = 0; j < precision && i + j < width; ++j)
                product[i + j] = (product[i + j] + input[i + 1] * inverse[j]) % MOD;
        product[0] = (2 + MOD - product[0]) % MOD;
        for (size_t i = 1; i < width; ++i) product[i] = (MOD - product[i]) % MOD;
        for (size_t i = 0; i < width; ++i) next[i] = 0;
        for (size_t i = 0; i < precision; ++i)
            for (size_t j = 0; i + j < width; ++j)
                next[i + j] = (next[i + j] + inverse[i] * product[j]) % MOD;
        for (size_t i = 0; i < width; ++i) inverse[i] = next[i];
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
