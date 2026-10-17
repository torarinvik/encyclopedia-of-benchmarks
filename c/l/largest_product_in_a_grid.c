/* Largest product of four adjacent values in a bounded grid. */
#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 63
#define MAX_INPUT_LENGTH 3971
#define MAX_CELL_VALUE 1000

int64_t largest_product_in_a_grid(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;

    const int64_t rows = values[0];
    const int64_t cols = values[1];
    if (rows < 0 || rows > MAX_DIMENSION || cols < 0 || cols > MAX_DIMENSION) return -1;

    const size_t expected_length = 2 + (size_t)rows * (size_t)cols;
    if (length != expected_length) return -1;
    for (size_t index = 2; index < length; ++index) {
        if (values[index] < 0 || values[index] > MAX_CELL_VALUE) return -1;
    }

    const int64_t row_steps[4] = {0, 1, 1, 1};
    const int64_t col_steps[4] = {1, 0, 1, -1};
    int64_t best = 0;
    for (size_t row = 0; row < (size_t)rows; ++row) {
        for (size_t col = 0; col < (size_t)cols; ++col) {
            for (size_t direction = 0; direction < 4; ++direction) {
                int64_t product = 1;
                for (int64_t offset = 0; offset < 4; ++offset) {
                    const int64_t next_row = (int64_t)row + offset * row_steps[direction];
                    const int64_t next_col = (int64_t)col + offset * col_steps[direction];
                    if (next_row < 0 || next_row >= rows || next_col < 0 || next_col >= cols) {
                        product = 0;
                        break;
                    }
                    const size_t index = 2 + (size_t)next_row * (size_t)cols + (size_t)next_col;
                    product *= values[index];
                }
                if (product > best) best = product;
            }
        }
    }
    return best;
}
