#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_SIZE (1u << MAX_N)
#define MAX_INPUT_LENGTH (1u + 2u * MAX_SIZE)
#define MODULUS INT64_C(998244353)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t bitwise_and_convolution(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    if (n_value < 0 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;
    const size_t size = (size_t)1u << n;
    if (length != 1 + 2 * size) return -1;

    for (size_t index = 0; index < 2 * size; ++index)
        if (input[1 + index] < 0 || input[1 + index] >= MODULUS) return -1;
    const size_t output_bytes = 8 * size;
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t a[MAX_SIZE] = {0};
    int64_t b[MAX_SIZE] = {0};
    for (size_t index = 0; index < size; ++index) {
        a[index] = input[1 + index];
        b[index] = input[1 + size + index];
    }
    for (size_t bit = 0; bit < n; ++bit) {
        const size_t bit_mask = (size_t)1u << bit;
        for (size_t mask = 0; mask < size; ++mask) {
            if ((mask & bit_mask) == 0) {
                a[mask] = (a[mask] + a[mask | bit_mask]) % MODULUS;
                b[mask] = (b[mask] + b[mask | bit_mask]) % MODULUS;
            }
        }
    }
    for (size_t mask = 0; mask < size; ++mask) a[mask] = (a[mask] * b[mask]) % MODULUS;
    for (size_t bit = 0; bit < n; ++bit) {
        const size_t bit_mask = (size_t)1u << bit;
        for (size_t mask = 0; mask < size; ++mask) {
            if ((mask & bit_mask) == 0) {
                a[mask] -= a[mask | bit_mask];
                if (a[mask] < 0) a[mask] += MODULUS;
            }
        }
    }
    for (size_t mask = 0; mask < size; ++mask)
        store_i64_le(output, 8 * mask, a[mask]);
    return (int64_t)output_bytes;
}
