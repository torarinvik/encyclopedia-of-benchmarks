#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

enum { MAX_N = 5, MAX_P = 32, MAX_INPUT = 66, MAX_OUTPUT = 256 };
static const int64_t MOD = INT64_C(998244353);

static void store_le(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) { out[at + b] = (uint8_t)(bits & 255u); bits >>= 8; }
}

int64_t mul_mod2n_convolution(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > MAX_N) return -1;
    size_t n = (size_t)input[0], p = (size_t)1 << n;
    if (length != 1 + 2 * p) return -1;
    for (size_t i = 1; i < length; ++i) if (input[i] < 0 || input[i] >= MOD) return -1;
    size_t bytes = 8 * p;
    if (bytes > MAX_OUTPUT) return -1;
    if (output == NULL || capacity < bytes) return -2;
    int64_t a[MAX_P], b[MAX_P], result[MAX_P] = {0};
    for (size_t i = 0; i < p; ++i) { a[i] = input[1 + i]; b[i] = input[1 + p + i]; }
    size_t mask = p - 1;
    for (size_t i = 0; i < p; ++i) for (size_t j = 0; j < p; ++j) {
        size_t k = (i * j) & mask;
        result[k] = (result[k] + a[i] * b[j]) % MOD;
    }
    for (size_t i = 0; i < p; ++i) store_le(output, 8 * i, result[i]);
    return (int64_t)bytes;
}
