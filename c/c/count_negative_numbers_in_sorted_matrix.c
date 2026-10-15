#include <stddef.h>
#include <stdint.h>

#define MAX_CELLS 512

int64_t count_negative_numbers_in_sorted_matrix(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > MAX_CELLS + 2) return -1;
    const int64_t rows_value = input[0];
    const int64_t columns_value = input[1];
    if (rows_value < 1 || rows_value > MAX_CELLS || columns_value < 1 || columns_value > MAX_CELLS) return -1;
    const size_t rows = (size_t)rows_value;
    const size_t columns = (size_t)columns_value;
    if (rows * columns > MAX_CELLS || length != 2 + rows * columns) return -1;

    size_t nonnegative = 0;
    size_t bound = columns;
    for (size_t row = 0; row < rows; ++row) {
        size_t left = 0;
        size_t right = bound;
        while (left < right) {
            const size_t middle = left + (right - left) / 2;
            const int64_t value = input[2 + row * columns + middle];
            if (value >= 0) left = middle + 1;
            else right = middle;
        }
        bound = left;
        nonnegative += bound;
    }
    return (int64_t)(rows * columns - nonnegative);
}
