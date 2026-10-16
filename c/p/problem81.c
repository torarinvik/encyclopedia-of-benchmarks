#include <stddef.h>
#include <stdint.h>

enum { MAX_DIMENSION = 80, MAX_CELL_VALUE = 9999 };

int64_t problem81(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1) return -1;
    const int64_t dimension_value = input[0];
    if (dimension_value < 1 || dimension_value > MAX_DIMENSION) return -1;
    const size_t dimension = (size_t)dimension_value;
    if (length != 1 + dimension * dimension) return -1;
    for (size_t index = 1; index < length; ++index)
        if (input[index] < 0 || input[index] > MAX_CELL_VALUE) return -1;

    int64_t costs[MAX_DIMENSION];
    costs[0] = input[1];
    for (size_t column = 1; column < dimension; ++column)
        costs[column] = costs[column - 1] + input[1 + column];
    for (size_t row = 1; row < dimension; ++row) {
        const size_t row_offset = 1 + row * dimension;
        costs[0] += input[row_offset];
        for (size_t column = 1; column < dimension; ++column) {
            const int64_t above = costs[column];
            const int64_t left = costs[column - 1];
            costs[column] = (above < left ? above : left) + input[row_offset + column];
        }
    }
    return costs[dimension - 1];
}
