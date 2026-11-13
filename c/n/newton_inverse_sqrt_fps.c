#include <stddef.h>
#include <stdint.h>

#define MOD INT64_C(998244353)
#define HALF INT64_C(499122177)
#define LIMIT 64

static void multiply(const int64_t *left, const int64_t *right,
                     size_t width, int64_t *result) {
    for (size_t i = 0; i < width; ++i) result[i] = 0;
    for (size_t i = 0; i < width; ++i)
        for (size_t j = 0; i + j < width; ++j)
            result[i + j] = (result[i + j] + left[i] * right[j]) % MOD;
}

int64_t newton_inverse_sqrt_fps(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 66) return -1;
    if (input[0] < 1 || input[0] > LIMIT) return -1;
    size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= MOD) return -1;
    if (input[1] != 1) return -1;
    size_t bytes = 8 * n;
    if (output == NULL || capacity < bytes) return -2;
    int64_t f[LIMIT] = {0}, inverse[LIMIT] = {0};
    int64_t square[LIMIT], product[LIMIT], correction[LIMIT], next[LIMIT];
    for (size_t i = 0; i < n; ++i) f[i] = input[i + 1];
    inverse[0] = 1;
    size_t precision = 1;
    while (precision < n) {
        size_t width = precision * 2 < n ? precision * 2 : n;
        multiply(inverse, inverse, width, square);
        multiply(f, square, width, product);
        correction[0] = (3 + MOD - product[0]) * HALF % MOD;
        for (size_t i = 1; i < width; ++i) correction[i] = (MOD - product[i]) * HALF % MOD;
        multiply(inverse, correction, width, next);
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
