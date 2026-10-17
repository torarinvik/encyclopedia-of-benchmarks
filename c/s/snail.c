#include <stddef.h>
#include <stdint.h>

enum {
    MAX_ROWS = 16,
    MAX_COLUMNS = 16,
    MAX_CELLS = MAX_ROWS * MAX_COLUMNS,
    MAX_INPUT_LENGTH = MAX_CELLS + 3
};

static void write_i32_le(uint8_t *output, size_t index, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    const size_t offset = index * 4u;
    output[offset] = (uint8_t)bits;
    output[offset + 1u] = (uint8_t)(bits >> 8u);
    output[offset + 2u] = (uint8_t)(bits >> 16u);
    output[offset + 3u] = (uint8_t)(bits >> 24u);
}

int64_t snail(const int32_t *values, size_t length,
              uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 2u || length > MAX_INPUT_LENGTH) return -1;

    const int32_t rows_value = values[0];
    const int32_t columns_value = values[1];
    if (rows_value < 0 || rows_value > MAX_ROWS
        || columns_value < 0 || columns_value > MAX_COLUMNS) return -1;
    if (rows_value == 0 && columns_value != 0) return -1;
    if (columns_value == 1 && rows_value != 1) return -1;

    const size_t rows = (size_t)rows_value;
    const size_t columns = (size_t)columns_value;
    const size_t cell_count = rows * columns;
    if (length != 2u + cell_count) return -1;

    const size_t required_bytes = 4u * cell_count;
    if (output == NULL || output_capacity < required_bytes) return -2;
    if (cell_count == 0u) return 0;

    int32_t matrix[MAX_CELLS];
    for (size_t index = 0; index < cell_count; ++index)
        matrix[index] = values[2u + index];

    int top = 0, bottom = (int)rows - 1;
    int left = 0, right = (int)columns - 1;
    size_t written = 0;
    while (top <= bottom && left <= right) {
        for (int column = left; column <= right; ++column)
            write_i32_le(output, written++, matrix[(size_t)top * columns + (size_t)column]);
        ++top;

        for (int row = top; row <= bottom; ++row)
            write_i32_le(output, written++, matrix[(size_t)row * columns + (size_t)right]);
        --right;

        if (top <= bottom && left <= right) {
            for (int column = right; column >= left; --column)
                write_i32_le(output, written++, matrix[(size_t)bottom * columns + (size_t)column]);
            --bottom;
        }

        if (top <= bottom && left <= right) {
            for (int row = bottom; row >= top; --row)
                write_i32_le(output, written++, matrix[(size_t)row * columns + (size_t)left]);
            ++left;
        }
    }
    return (int64_t)required_bytes;
}
