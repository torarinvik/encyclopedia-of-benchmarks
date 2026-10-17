/* Traverse a bounded rectangular matrix clockwise and emit signed-i64 bytes. */
#include <stddef.h>
#include <stdint.h>

enum {
    MIN_ROWS = 1,
    MAX_ROWS = 16,
    MIN_COLUMNS = 2,
    MAX_COLUMNS = 16,
    MAX_CELLS = MAX_ROWS * MAX_COLUMNS,
    MAX_INPUT_LENGTH = 259,
    MAX_OUTPUT_BYTES = 8 * MAX_CELLS
};

static void write_i64_little_endian(uint8_t *output, size_t offset, int32_t value) {
    const uint64_t bits = (uint64_t)(int64_t)value;
    for (size_t byte_index = 0; byte_index < 8; ++byte_index) {
        output[offset + byte_index] = (uint8_t)(bits >> (8 * byte_index));
    }
}

int64_t spiral_print(const int64_t *input, size_t length,
                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;

    const int64_t rows_value = input[0];
    const int64_t columns_value = input[1];
    if (rows_value < MIN_ROWS || rows_value > MAX_ROWS
        || columns_value < MIN_COLUMNS || columns_value > MAX_COLUMNS) {
        return -1;
    }

    const size_t rows = (size_t)rows_value;
    const size_t columns = (size_t)columns_value;
    const size_t cell_count = rows * columns;
    if (length != 2 + cell_count) return -1;

    int32_t matrix[MAX_CELLS];
    for (size_t index = 0; index < cell_count; ++index) {
        const int64_t value = input[2 + index];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        matrix[index] = (int32_t)value;
    }

    const size_t required_bytes = 8 * cell_count;
    if (output == NULL || capacity < required_bytes) return -2;

    int32_t order[MAX_CELLS];
    size_t order_length = 0;
    size_t top = 0, bottom = rows - 1;
    size_t left = 0, right = columns - 1;
    while (top <= bottom && left <= right) {
        for (size_t column = left; column <= right; ++column) {
            order[order_length++] = matrix[top * columns + column];
        }
        ++top;

        for (size_t row = top; row <= bottom; ++row) {
            order[order_length++] = matrix[row * columns + right];
        }
        --right;

        if (top <= bottom && left <= right) {
            for (size_t column = right;; --column) {
                order[order_length++] = matrix[bottom * columns + column];
                if (column == left) break;
            }
            --bottom;
        }

        if (top <= bottom && left <= right) {
            for (size_t row = bottom;; --row) {
                order[order_length++] = matrix[row * columns + left];
                if (row == top) break;
            }
            ++left;
        }
    }

    for (size_t index = 0; index < order_length; ++index) {
        write_i64_little_endian(output, 8 * index, order[index]);
    }
    return (int64_t)required_bytes;
}
