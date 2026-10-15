#include <stddef.h>
#include <stdint.h>

static void store_i64_le(int64_t value, uint8_t *output, size_t offset) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t matrix_multiplication(const int64_t *input, size_t length,
                              uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 1) return -2;
    const int64_t dimension = input[0];
    if (dimension < 2 || dimension > 8) return -2;
    const size_t n = (size_t)dimension;
    const size_t cells = n * n;
    if (length != 1 + 2 * cells) return -2;
    for (size_t index = 0; index < 2 * cells; ++index) {
        if (input[1 + index] < -1000 || input[1 + index] > 1000) return -2;
    }
    if (output == NULL || output_capacity < cells * 8) return -3;

    for (size_t row = 0; row < n; ++row) {
        for (size_t column = 0; column < n; ++column) {
            int64_t sum = 0;
            for (size_t index = 0; index < n; ++index) {
                sum += input[1 + row * n + index] * input[1 + cells + index * n + column];
            }
            store_i64_le(sum, output, (row * n + column) * 8);
        }
    }
    return (int64_t)cells;
}
