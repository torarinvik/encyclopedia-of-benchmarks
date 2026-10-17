#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION INT64_C(8)
#define MAX_INPUT_LENGTH ((size_t)67)
#define MAX_CELLS ((size_t)64)
#define MIN_CELL INT64_C(-1000000)
#define MAX_CELL INT64_C(1000000)

static void write_i64_le(uint8_t *output, size_t position, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[position + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t set_matrix_zeroes(const int64_t *input, size_t length,
                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t rows_value = input[0];
    const int64_t columns_value = input[1];
    if (rows_value < 1 || rows_value > MAX_DIMENSION ||
        columns_value < 1 || columns_value > MAX_DIMENSION) return -1;
    const size_t rows = (size_t)rows_value;
    const size_t columns = (size_t)columns_value;
    const size_t cells = rows * columns;
    if (length != 2 + cells) return -1;

    int64_t matrix[MAX_CELLS];
    for (size_t index = 0; index < cells; ++index) {
        const int64_t value = input[2 + index];
        if (value < MIN_CELL || value > MAX_CELL) return -1;
        matrix[index] = value;
    }

    const size_t bytes = cells * 8;
    if (output == NULL || capacity < bytes) return -2;

    int first_column_zero = 0;
    for (size_t row = 0; row < rows; ++row) {
        if (matrix[row * columns] == 0) first_column_zero = 1;
        for (size_t column = 1; column < columns; ++column) {
            if (matrix[row * columns + column] == 0) {
                matrix[row * columns] = 0;
                matrix[column] = 0;
            }
        }
    }
    for (size_t row = 1; row < rows; ++row) {
        for (size_t column = 1; column < columns; ++column) {
            if (matrix[row * columns] == 0 || matrix[column] == 0)
                matrix[row * columns + column] = 0;
        }
    }
    if (matrix[0] == 0) {
        for (size_t column = 0; column < columns; ++column) matrix[column] = 0;
    }
    if (first_column_zero) {
        for (size_t row = 0; row < rows; ++row) matrix[row * columns] = 0;
    }

    for (size_t index = 0; index < cells; ++index)
        write_i64_le(output, index * 8, matrix[index]);
    return (int64_t)bytes;
}
