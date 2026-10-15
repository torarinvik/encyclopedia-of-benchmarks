/* Build a padded two-dimensional prefix table and answer one inclusive rectangle. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN
#define MAX_DIMENSION 16

int64_t prefix_sum2_d(const int64_t *input, size_t length)
{
    if (input == NULL || length < 7) return INVALID_RESULT;
    const int64_t raw_rows = input[0], raw_cols = input[1];
    if (raw_rows < 1 || raw_rows > MAX_DIMENSION || raw_cols < 1 || raw_cols > MAX_DIMENSION) return INVALID_RESULT;
    const size_t rows = (size_t)raw_rows, cols = (size_t)raw_cols;
    if (length != 2 + rows * cols + 4) return INVALID_RESULT;
    const size_t query = 2 + rows * cols;
    const int64_t row1v = input[query], col1v = input[query + 1];
    const int64_t row2v = input[query + 2], col2v = input[query + 3];
    if (row1v < 0 || col1v < 0 || row2v < row1v || col2v < col1v ||
        (uint64_t)row2v >= rows || (uint64_t)col2v >= cols) return INVALID_RESULT;
    int64_t prefix[MAX_DIMENSION + 1][MAX_DIMENSION + 1] = {{0}};
    for (size_t i = 0; i < rows; ++i) {
        for (size_t j = 0; j < cols; ++j) {
            const int64_t value = input[2 + i * cols + j];
            if (value < -1000 || value > 1000) return INVALID_RESULT;
            prefix[i + 1][j + 1] = value + prefix[i][j + 1] + prefix[i + 1][j] - prefix[i][j];
        }
    }
    const size_t row1 = (size_t)row1v, col1 = (size_t)col1v;
    const size_t row2 = (size_t)row2v, col2 = (size_t)col2v;
    return prefix[row2 + 1][col2 + 1] - prefix[row1][col2 + 1] -
           prefix[row2 + 1][col1] + prefix[row1][col1];
}
