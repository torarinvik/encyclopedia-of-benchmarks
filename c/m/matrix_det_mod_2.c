#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_INPUT_VALUES (1 + MAX_N * MAX_N)

static void store_i64_le(uint8_t *output, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t matrix_det_mod_2(const int64_t *input, size_t length,
                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;
    if (length != 1 + n * n) return -1;

    uint64_t rows[MAX_N] = {0};
    for (size_t row = 0; row < n; ++row) {
        for (size_t column = 0; column < n; ++column) {
            const int64_t bit = input[1 + row * n + column];
            if (bit != 0 && bit != 1) return -1;
            rows[row] |= (uint64_t)bit << column;
        }
    }

    size_t pivot_row = 0;
    for (size_t column = 0; column < n; ++column) {
        size_t pivot = pivot_row;
        while (pivot < n && ((rows[pivot] >> column) & 1u) == 0) ++pivot;
        if (pivot == n) continue;
        const uint64_t temporary = rows[pivot_row];
        rows[pivot_row] = rows[pivot];
        rows[pivot] = temporary;
        for (size_t row = pivot_row + 1; row < n; ++row)
            if (((rows[row] >> column) & 1u) != 0) rows[row] ^= rows[pivot_row];
        ++pivot_row;
    }

    if (output == NULL || capacity < 8) return -2;
    store_i64_le(output, (int64_t)(pivot_row == n));
    return 8;
}
