#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_SIZE = 1 << MAX_N, MAX_INPUT = 1 + 2 * MAX_SIZE };
#define MODULUS INT64_C(998244353)

static void xor_walsh_transform(int64_t *values, size_t size) {
    for (size_t half = 1; half < size; half *= 2) {
        for (size_t block = 0; block < size; block += 2 * half) {
            for (size_t offset = 0; offset < half; ++offset) {
                const int64_t left = values[block + offset];
                const int64_t right = values[block + half + offset];
                values[block + offset] = (left + right) % MODULUS;
                values[block + half + offset] = (left - right + MODULUS) % MODULUS;
            }
        }
    }
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t bitwise_xor_convolution(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (!input || length < 1 || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0];
    if (n_value < 0 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;
    const size_t size = (size_t)1 << n;
    if (length != 1 + 2 * size) return -1;
    for (size_t index = 0; index < 2 * size; ++index)
        if (input[1 + index] < 0 || input[1 + index] >= MODULUS) return -1;

    const size_t output_bytes = 8 * size;
    if (!output || capacity < output_bytes) return -2;
    int64_t first[MAX_SIZE] = {0};
    int64_t second[MAX_SIZE] = {0};
    for (size_t index = 0; index < size; ++index) {
        first[index] = input[1 + index];
        second[index] = input[1 + size + index];
    }
    xor_walsh_transform(first, size);
    xor_walsh_transform(second, size);
    for (size_t index = 0; index < size; ++index)
        first[index] = (first[index] * second[index]) % MODULUS;
    xor_walsh_transform(first, size);

    int64_t inverse_size = 1;
    for (size_t bit = 0; bit < n; ++bit)
        inverse_size = (inverse_size * ((MODULUS + 1) / 2)) % MODULUS;
    for (size_t index = 0; index < size; ++index)
        store_i64_le(output, 8 * index, (first[index] * inverse_size) % MODULUS);
    return (int64_t)output_bytes;
}
