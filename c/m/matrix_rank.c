#include <stddef.h>
#include <stdint.h>

#define MATRIX_RANK_MAX_INPUT_LENGTH 66
#define MATRIX_RANK_MAX_DIMENSION 8
#define MATRIX_RANK_EPSILON 1e-10

static int matrix_rank_is_zero(double value) {
    const double magnitude = value < 0.0 ? -value : value;
    return magnitude < MATRIX_RANK_EPSILON;
}

int64_t matrix_rank(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > MATRIX_RANK_MAX_INPUT_LENGTH) return -1;
    const int64_t rows_value = values[0];
    const int64_t cols_value = values[1];
    if (rows_value < 1 || rows_value > MATRIX_RANK_MAX_DIMENSION ||
        cols_value < 1 || cols_value > MATRIX_RANK_MAX_DIMENSION) return -1;

    const size_t rows = (size_t)rows_value;
    const size_t cols = (size_t)cols_value;
    const size_t cells = rows * cols;
    if (length != 2 + cells) return -1;

    double matrix[64];
    int row_marked[8] = {0};
    for (size_t index = 0; index < cells; ++index) {
        if (values[2 + index] != 0 && values[2 + index] != 1) return -1;
        matrix[index] = (double)values[2 + index];
    }

    int64_t rank = 0;
    for (size_t col = 0; col < cols; ++col) {
        size_t pivot_row = rows;
        for (size_t row = 0; row < rows; ++row) {
            if (!row_marked[row] && !matrix_rank_is_zero(matrix[row * cols + col])) {
                pivot_row = row;
                break;
            }
        }
        if (pivot_row == rows) continue;

        ++rank;
        row_marked[pivot_row] = 1;
        const double pivot_value = matrix[pivot_row * cols + col];
        for (size_t next_col = col + 1; next_col < cols; ++next_col) {
            matrix[pivot_row * cols + next_col] /= pivot_value;
        }
        for (size_t other_row = 0; other_row < rows; ++other_row) {
            if (other_row == pivot_row) continue;
            const double factor = matrix[other_row * cols + col];
            if (!matrix_rank_is_zero(factor)) {
                for (size_t next_col = col + 1; next_col < cols; ++next_col) {
                    matrix[other_row * cols + next_col] -=
                        matrix[pivot_row * cols + next_col] * factor;
                }
            }
        }
    }
    return rank;
}
