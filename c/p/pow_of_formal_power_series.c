#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 32, MAX_INPUT = 34 };
static const int64_t MODULUS = INT64_C(998244353);

static void multiply_truncated(const int64_t *left, const int64_t *right,
                               size_t n, int64_t *product)
{
    for (size_t i = 0; i < n; ++i) product[i] = 0;
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j < n - i; ++j)
            product[i + j] = (product[i + j] + left[i] * right[j]) % MODULUS;
    }
}

static void store_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t pow_of_formal_power_series(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > INT64_C(1000000000000000000)) return -1;
    const size_t n = (size_t)input[0];
    if (length != n + 2) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 2] < 0 || input[i + 2] >= MODULUS) return -1;

    const size_t bytes = 8 * n;
    if (output == NULL || capacity < bytes) return -2;
    int64_t result[MAX_N] = {0};
    int64_t base[MAX_N] = {0};
    int64_t temporary[MAX_N] = {0};
    result[0] = 1;
    for (size_t i = 0; i < n; ++i) base[i] = input[i + 2];
    int64_t exponent = input[1];
    while (exponent > 0) {
        if (exponent & 1) {
            multiply_truncated(result, base, n, temporary);
            for (size_t i = 0; i < n; ++i) result[i] = temporary[i];
        }
        exponent >>= 1;
        if (exponent > 0) {
            multiply_truncated(base, base, n, temporary);
            for (size_t i = 0; i < n; ++i) base[i] = temporary[i];
        }
    }
    for (size_t i = 0; i < n; ++i) store_le(output, 8 * i, result[i]);
    return (int64_t)bytes;
}
