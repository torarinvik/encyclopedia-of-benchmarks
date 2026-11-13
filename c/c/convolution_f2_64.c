#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_M = 8, MAX_INPUT = 18, MAX_PARSEABLE = 19, MAX_OUTPUT = 120 };

static uint64_t gf2_64_multiply(uint64_t left, uint64_t right) {
    uint64_t result = 0;
    uint64_t shifted = left;
    for (unsigned bit = 0; bit < 64; ++bit) {
        if (right & UINT64_C(1)) result ^= shifted;
        const uint64_t carry = shifted >> 63;
        shifted <<= 1;
        if (carry) shifted ^= UINT64_C(0x1b);
        right >>= 1;
    }
    return result;
}

int64_t convolution_f2_64(const int64_t *input, size_t length,
                          uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_M) return -1;
    const size_t n = (size_t)input[0], m = (size_t)input[1];
    if (length != 2 + n + m) return -1;

    const size_t output_count = n + m - 1;
    const size_t needed = 8 * output_count;
    if (output == NULL || output_capacity < needed) return -2;

    uint64_t a[MAX_N], b[MAX_M], product[MAX_N + MAX_M - 1] = {0};
    for (size_t i = 0; i < n; ++i) a[i] = (uint64_t)input[2 + i];
    for (size_t j = 0; j < m; ++j) b[j] = (uint64_t)input[2 + n + j];
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < m; ++j)
            product[i + j] ^= gf2_64_multiply(a[i], b[j]);

    for (size_t i = 0; i < output_count; ++i)
        for (unsigned byte = 0; byte < 8; ++byte)
            output[8 * i + byte] = (uint8_t)(product[i] >> (8 * byte));
    return (int64_t)needed;
}
