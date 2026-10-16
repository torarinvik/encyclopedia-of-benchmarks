/* Top-right staircase search for a strictly increasing integer matrix. */
#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 32

int64_t saddleback_search(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3) return -1;
    const int64_t rows_value = values[0], columns_value = values[1];
    const int64_t target = values[2];
    if (rows_value <= 0 || rows_value > MAX_DIMENSION ||
        columns_value <= 0 || columns_value > MAX_DIMENSION ||
        target < INT32_MIN || target > INT32_MAX) return -1;
    const size_t rows = (size_t)rows_value, columns = (size_t)columns_value;
    const size_t cells = rows * columns;
    if (length != 3 + cells) return -1;
    const int64_t *matrix = values + 3;
    for (size_t index = 0; index < cells; ++index) {
        if (matrix[index] < INT32_MIN || matrix[index] > INT32_MAX) return -1;
    }

    size_t row = 0, column = columns - 1;
    while (row < rows) {
        const int64_t value = matrix[row * columns + column];
        if (value == target) return (int64_t)(row * columns + column + 1);
        if (value < target) {
            ++row;
        } else if (column == 0) {
            break;
        } else {
            --column;
        }
    }
    return 0;
}
