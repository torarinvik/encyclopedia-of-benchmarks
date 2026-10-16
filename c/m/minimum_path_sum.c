#include <stddef.h>
#include <stdint.h>

int64_t minimum_path_sum(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 66) return INT64_MIN;
    const int64_t row_value = values[0], column_value = values[1];
    if (row_value < 1 || row_value > 8 || column_value < 1 || column_value > 8) return INT64_MIN;
    const size_t rows = (size_t)row_value, columns = (size_t)column_value;
    if (length != 2 + rows * columns) return INT64_MIN;
    int64_t costs[8] = {0};
    for (size_t row = 0; row < rows; ++row) {
        for (size_t column = 0; column < columns; ++column) {
            const int64_t cell = values[2 + row * columns + column];
            if (cell < 0 || cell > 1000) return INT64_MIN;
            if (row == 0 && column == 0) costs[column] = cell;
            else if (row == 0) costs[column] = costs[column - 1] + cell;
            else if (column == 0) costs[column] += cell;
            else costs[column] = (costs[column - 1] < costs[column] ? costs[column - 1] : costs[column]) + cell;
        }
    }
    return costs[columns - 1];
}
