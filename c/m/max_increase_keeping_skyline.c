/* Return the total allowable increase while preserving every row and column skyline. */
#include <stddef.h>
#include <stdint.h>

#define MAX_GRID_SIZE 50

int64_t max_increase_keeping_skyline(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 1 + MAX_GRID_SIZE * MAX_GRID_SIZE) return -1;
    if (values[0] < 2 || values[0] > MAX_GRID_SIZE) return -1;
    const size_t size = (size_t)values[0];
    if (length != 1 + size * size) return -1;

    int64_t row_max[MAX_GRID_SIZE] = {0};
    int64_t column_max[MAX_GRID_SIZE] = {0};
    for (size_t row = 0; row < size; ++row) {
        for (size_t column = 0; column < size; ++column) {
            const int64_t height = values[1 + row * size + column];
            if (height < 0 || height > 100) return -1;
            if (height > row_max[row]) row_max[row] = height;
            if (height > column_max[column]) column_max[column] = height;
        }
    }

    int64_t total = 0;
    for (size_t row = 0; row < size; ++row) {
        for (size_t column = 0; column < size; ++column) {
            const int64_t height = values[1 + row * size + column];
            const int64_t skyline = row_max[row] < column_max[column]
                ? row_max[row] : column_max[column];
            total += skyline - height;
        }
    }
    return total;
}
