#include <stddef.h>
#include <stdint.h>

enum { MAX_ROWS = 80, MAX_COLUMNS = 80, MAX_CELL_VALUE = 9999 };

int64_t problem82(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3) return -1;
    const int64_t row_value = input[0];
    const int64_t column_value = input[1];
    if (row_value < 1 || row_value > MAX_ROWS || column_value < 1 || column_value > MAX_COLUMNS) return -1;
    const size_t rows = (size_t)row_value;
    const size_t columns = (size_t)column_value;
    if (length != 2 + rows * columns) return -1;
    for (size_t index = 2; index < length; ++index)
        if (input[index] < 0 || input[index] > MAX_CELL_VALUE) return -1;

    int64_t costs[MAX_ROWS];
    for (size_t row = 0; row < rows; ++row) costs[row] = input[2 + row * columns];
    for (size_t column = 1; column < columns; ++column) {
        const size_t offset = 2 + column;
        for (size_t row = 0; row < rows; ++row)
            costs[row] += input[offset + row * columns];
        for (size_t row = 1; row < rows; ++row) {
            const int64_t from_above = costs[row - 1] + input[offset + row * columns];
            if (from_above < costs[row]) costs[row] = from_above;
        }
        for (size_t row = rows - 1; row > 0; --row) {
            const int64_t from_below = costs[row] + input[offset + (row - 1) * columns];
            if (from_below < costs[row - 1]) costs[row - 1] = from_below;
        }
    }
    int64_t best = costs[0];
    for (size_t row = 1; row < rows; ++row) if (costs[row] < best) best = costs[row];
    return best;
}
