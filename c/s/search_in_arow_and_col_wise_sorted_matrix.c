#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 63
#define MAX_INPUT_VALUES (2 + MAX_DIMENSION * MAX_DIMENSION)

static void write_i32_le(uint8_t *output, size_t offset, int64_t value) {
    const uint32_t bits = (uint32_t)(int32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t search_in_arow_and_col_wise_sorted_matrix(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0];
    const int64_t target = input[1];
    if (n_value < 1 || n_value > MAX_DIMENSION || target < INT32_MIN || target > INT32_MAX) return -1;
    const size_t n = (size_t)n_value;
    if (length != 2 + n * n) return -1;

    size_t target_count = 0;
    for (size_t row = 0; row < n; ++row) {
        for (size_t column = 0; column < n; ++column) {
            const size_t index = row * n + column;
            const int64_t value = input[2 + index];
            if (value < INT32_MIN || value > INT32_MAX) return -1;
            if (column > 0 && value < input[2 + index - 1]) return -1;
            if (row > 0 && value < input[2 + index - n]) return -1;
            if (value == target && ++target_count > 1) return -1;
        }
    }

    size_t row = 0;
    int64_t column = (int64_t)n - 1;
    int64_t result_row = -1, result_column = -1, found = 0;
    while (row < n && column >= 0) {
        const int64_t value = input[2 + row * n + (size_t)column];
        if (value == target) {
            result_row = (int64_t)row;
            result_column = column;
            found = 1;
            break;
        }
        if (target > value) ++row;
        else --column;
    }

    if (output == NULL || capacity < 8) return -2;
    uint8_t buffer[8];
    write_i32_le(buffer, 0, result_row);
    write_i32_le(buffer, 4, result_column);
    for (size_t index = 0; index < 8; ++index) output[index] = buffer[index];
    return found;
}
