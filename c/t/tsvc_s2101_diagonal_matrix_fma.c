#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_CELLS (MAX_N * MAX_N)
#define MAX_INPUT_LENGTH (1 + 3 * MAX_CELLS)
#define MAX_VALUE INT64_C(100)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t tsvc_s2101_diagonal_matrix_fma(const int64_t *input, size_t length,
                                        uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_raw = input[0];
    if (n_raw < 1 || n_raw > MAX_N) return -1;
    const size_t n = (size_t)n_raw;
    const size_t cells = n * n;
    if (length != 1 + 3 * cells) return -1;
    for (size_t i = 0; i < 3 * cells; ++i)
        if (input[i + 1] < -MAX_VALUE || input[i + 1] > MAX_VALUE) return -1;
    if (output == NULL || output_capacity < 8 * cells) return -2;

    for (size_t cell = 0; cell < cells; ++cell)
        store_i64_le(output, 8 * cell, input[cell + 1]);
    for (size_t i = 0; i < n; ++i) {
        const size_t diagonal = i * n + i;
        const int64_t value = input[1 + diagonal] +
            input[1 + cells + diagonal] * input[1 + 2 * cells + diagonal];
        store_i64_le(output, 8 * diagonal, value);
    }
    return (int64_t)cells;
}
