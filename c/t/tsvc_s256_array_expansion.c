#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_CELLS (MAX_N * MAX_N)
#define MAX_INPUT_LENGTH (2 + MAX_N + 2 * MAX_CELLS)
#define MAX_A0 INT64_C(1000)
#define MAX_FACTOR INT64_C(1000)
#define MAX_C0 INT64_C(1000000)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t tsvc_s256_array_expansion(const int64_t *input, size_t length,
                                 uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_raw = input[0];
    const int64_t a0 = input[1];
    if (n_raw < 1 || n_raw > MAX_N || a0 < -MAX_A0 || a0 > MAX_A0) return -1;
    const size_t n = (size_t)n_raw;
    const size_t cells = n * n;
    if (length != 2 + n + 2 * cells) return -1;
    const size_t d_start = 2;
    const size_t b_start = d_start + n;
    const size_t c_start = b_start + cells;
    for (size_t i = 0; i < n; ++i)
        if (input[d_start + i] < -MAX_FACTOR || input[d_start + i] > MAX_FACTOR) return -1;
    for (size_t i = 0; i < cells; ++i) {
        if (input[b_start + i] < -MAX_FACTOR || input[b_start + i] > MAX_FACTOR ||
            input[c_start + i] < -MAX_C0 || input[c_start + i] > MAX_C0) return -1;
    }

    const size_t output_values = n + cells;
    if (output == NULL || output_capacity < output_values * 8) return -2;
    int64_t a[MAX_N] = {0};
    int64_t c[MAX_CELLS];
    a[0] = a0;
    for (size_t cell = 0; cell < cells; ++cell) c[cell] = input[c_start + cell];
    for (size_t column = 0; column < n; ++column) {
        for (size_t row = 1; row < n; ++row) {
            a[row] = 1 - a[row - 1];
            const size_t cell = row * n + column;
            c[cell] = a[row] + input[b_start + cell] * input[d_start + row];
        }
    }
    for (size_t row = 0; row < n; ++row) store_i64_le(output, row * 8, a[row]);
    for (size_t cell = 0; cell < cells; ++cell)
        store_i64_le(output, (n + cell) * 8, c[cell]);
    return (int64_t)output_values;
}
