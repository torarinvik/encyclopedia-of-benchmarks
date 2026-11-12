#include <stddef.h>
#include <stdint.h>

enum { MAX_COEFFICIENTS = 8, MAX_N = 4, MAX_SIZE = 16, MAX_INPUT = 27 };
static const int64_t MODULUS = INT64_C(998244353);

static void store_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t polynomial_composite_set_power_series(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > MAX_COEFFICIENTS ||
        input[1] < 0 || input[1] > MAX_N) return -1;
    const size_t count = (size_t)input[0];
    const size_t n = (size_t)input[1];
    const size_t size = (size_t)1 << n;
    if (length != 2 + count + size) return -1;
    for (size_t i = 0; i < count + size; ++i)
        if (input[2 + i] < 0 || input[2 + i] >= MODULUS) return -1;

    const size_t bytes = 8 * size;
    if (output == NULL || capacity < bytes) return -2;

    int64_t series[MAX_SIZE] = {0};
    int64_t result[MAX_SIZE] = {0};
    int64_t temporary[MAX_SIZE] = {0};
    for (size_t mask = 0; mask < size; ++mask)
        series[mask] = input[2 + count + mask];

    for (size_t degree = count; degree > 0; --degree) {
        for (size_t mask = 0; mask < size; ++mask) {
            int64_t total = 0;
            size_t subset = mask;
            for (;;) {
                total = (total + result[subset] * series[mask ^ subset]) % MODULUS;
                if (subset == 0) break;
                subset = (subset - 1) & mask;
            }
            temporary[mask] = total;
        }
        temporary[0] = (temporary[0] + input[1 + degree]) % MODULUS;
        for (size_t mask = 0; mask < size; ++mask)
            result[mask] = temporary[mask];
    }

    for (size_t mask = 0; mask < size; ++mask)
        store_le(output, 8 * mask, result[mask]);
    return (int64_t)bytes;
}
