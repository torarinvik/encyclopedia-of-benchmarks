#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_CELLS 100000
#define MAX_DIMENSION 100000

static int64_t read_count(const uint8_t *output, size_t cell)
{
    const size_t position = 4 * cell;
    return (int64_t)((uint32_t)output[position] |
                     ((uint32_t)output[position + 1] << 8) |
                     ((uint32_t)output[position + 2] << 16) |
                     ((uint32_t)output[position + 3] << 24));
}

static void write_i32_le(uint8_t *output, size_t cell, int64_t value)
{
    const uint32_t encoded = (uint32_t)(int32_t)value;
    const size_t position = 4 * cell;
    output[position] = (uint8_t)encoded;
    output[position + 1] = (uint8_t)(encoded >> 8);
    output[position + 2] = (uint8_t)(encoded >> 16);
    output[position + 3] = (uint8_t)(encoded >> 24);
}

int64_t ones_minus_zeros(const int64_t *values, size_t length,
                         uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2 || values[0] < 1 || values[0] > MAX_DIMENSION ||
        values[1] < 1 || values[1] > MAX_DIMENSION) return -1;
    const size_t rows = (size_t)values[0];
    const size_t columns = (size_t)values[1];
    if (rows > MAX_CELLS / columns) return -1;
    const size_t cells = rows * columns;
    if (length != 2 + cells) return -1;
    for (size_t cell = 0; cell < cells; ++cell)
        if (values[2 + cell] != 0 && values[2 + cell] != 1) return -1;
    const size_t required = 4 * cells;
    if (output == NULL || output_capacity < required) return -2;

    memset(output, 0, required);
    int64_t row_zero_ones = 0;
    int64_t column_zero_ones = 0;
    for (size_t row = 0; row < rows; ++row) {
        for (size_t column = 0; column < columns; ++column) {
            if (values[2 + row * columns + column] == 0) continue;
            if (row == 0) ++row_zero_ones;
            else {
                const size_t slot = row * columns;
                write_i32_le(output, slot, read_count(output, slot) + 1);
            }
            if (column == 0) ++column_zero_ones;
            else write_i32_le(output, column, read_count(output, column) + 1);
        }
    }

    for (size_t row = rows; row > 1; --row) {
        const size_t current_row = row - 1;
        const size_t row_slot = current_row * columns;
        const int64_t ones_in_row = read_count(output, row_slot);
        for (size_t column = 0; column < columns; ++column) {
            const int64_t ones_in_column = column == 0 ? column_zero_ones : read_count(output, column);
            const int64_t difference = 2 * ones_in_row + 2 * ones_in_column -
                                       (int64_t)rows - (int64_t)columns;
            write_i32_le(output, row_slot + column, difference);
        }
    }
    for (size_t column = 0; column < columns; ++column) {
        const int64_t ones_in_column = column == 0 ? column_zero_ones : read_count(output, column);
        const int64_t difference = 2 * row_zero_ones + 2 * ones_in_column -
                                   (int64_t)rows - (int64_t)columns;
        write_i32_le(output, column, difference);
    }
    return (int64_t)cells;
}
