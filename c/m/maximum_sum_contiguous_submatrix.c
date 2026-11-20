#include <stddef.h>
#include <stdint.h>

#define MAX_ROWS 8
#define MAX_COLUMNS 8
#define MAX_PARSEABLE_INPUT_LENGTH 67
#define MAX_OUTPUT_BYTES 8

static void write_i64_le(uint8_t *output, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[byte] = (uint8_t)(bits >> (byte * 8));
    }
}

int64_t maximum_sum_contiguous_submatrix(const int64_t *input, size_t length,
                                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t rows_value = input[0];
    const int64_t columns_value = input[1];
    if (rows_value < 1 || rows_value > MAX_ROWS ||
        columns_value < 1 || columns_value > MAX_COLUMNS) return -1;
    const size_t rows = (size_t)rows_value;
    const size_t columns = (size_t)columns_value;
    if (length != 2 + rows * columns) return -1;
    for (size_t index = 0; index < rows * columns; ++index) {
        if (input[index + 2] < -1000 || input[index + 2] > 1000) return -1;
    }

    int64_t best = -64001;
    int64_t column_sums[MAX_COLUMNS] = {0};
    for (size_t top = 0; top < rows; ++top) {
        for (size_t column = 0; column < columns; ++column) column_sums[column] = 0;
        for (size_t bottom = top; bottom < rows; ++bottom) {
            const size_t row_offset = 2 + bottom * columns;
            for (size_t column = 0; column < columns; ++column) {
                column_sums[column] += input[row_offset + column];
            }
            int64_t current = column_sums[0];
            if (current > best) best = current;
            for (size_t column = 1; column < columns; ++column) {
                current = current < 0 ? column_sums[column]
                                      : current + column_sums[column];
                if (current > best) best = current;
            }
        }
    }
    if (output == NULL || capacity < MAX_OUTPUT_BYTES) return -2;
    write_i64_le(output, best);
    return MAX_OUTPUT_BYTES;
}
