/* Recursive row search matching the pinned matrix-search source. */
#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 32

static int64_t search_row(const int64_t *values, size_t base, int64_t lower,
                          int64_t upper, int64_t target)
{
    const int64_t middle = (lower + upper) / 2;
    const int64_t value = values[base + (size_t)middle];
    if (value == target) return middle;
    if (lower >= upper) return -1;
    if (value < target) return search_row(values, base, middle + 1, upper, target);
    return search_row(values, base, lower, middle - 1, target);
}

int64_t binary_search_matrix(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3) return -1;
    const int64_t rows_value = values[0], columns_value = values[1], target = values[2];
    if (rows_value <= 0 || rows_value > MAX_DIMENSION || columns_value <= 0 ||
        columns_value > MAX_DIMENSION) return -1;
    const size_t rows = (size_t)rows_value, columns = (size_t)columns_value;
    if (length != 3 + rows * columns) return -1;
    const int64_t *matrix = values + 3;
    if (matrix[0] == target) return 0;
    for (size_t row = 0; row < rows && matrix[row * columns] < target; ++row) {
        const int64_t column = search_row(matrix, row * columns, 0,
                                          (int64_t)columns - 1, target);
        if (column != -1) return (int64_t)(row * columns) + column;
    }
    return -1;
}
