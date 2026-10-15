#include <stddef.h>
#include <stdint.h>

static int64_t search_row(const int64_t *matrix, int64_t row_base,
                          int64_t low, int64_t high, int64_t target)
{
    while (low <= high) {
        const int64_t middle = low + (high - low) / 2;
        const int64_t value = matrix[row_base + middle];
        if (value == target) return middle;
        if (value < target) low = middle + 1;
        else high = middle - 1;
    }
    return -1;
}

int64_t binary_search2d_array(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3) return -1;
    const int64_t rows = values[0], cols = values[1], target = values[2];
    if (rows < 2 || rows > 32 || cols < 3 || cols > 32) return -1;
    if (length != 3 + (size_t)(rows * cols)) return -1;
    const int64_t *matrix = values + 3;
    const int64_t middle_col = cols / 2;
    int64_t start_row = 0, end_row = rows - 1;
    while (start_row < end_row - 1) {
        const int64_t middle_row = start_row + (end_row - start_row) / 2;
        const int64_t value = matrix[middle_row * cols + middle_col];
        if (value == target) return middle_row * cols + middle_col;
        if (value < target) start_row = middle_row;
        else end_row = middle_row;
    }
    if (matrix[start_row * cols + middle_col] == target) return start_row * cols + middle_col;
    if (matrix[end_row * cols + middle_col] == target) return end_row * cols + middle_col;
    if (target <= matrix[start_row * cols + middle_col - 1]) {
        const int64_t col = search_row(matrix, start_row * cols, 0, middle_col - 1, target);
        return col < 0 ? -1 : start_row * cols + col;
    }
    if (target >= matrix[start_row * cols + middle_col + 1] &&
        target <= matrix[start_row * cols + cols - 1]) {
        const int64_t col = search_row(matrix, start_row * cols, middle_col + 1, cols - 1, target);
        return col < 0 ? -1 : start_row * cols + col;
    }
    if (target <= matrix[end_row * cols + middle_col - 1]) {
        const int64_t col = search_row(matrix, end_row * cols, 0, middle_col - 1, target);
        return col < 0 ? -1 : end_row * cols + col;
    }
    const int64_t col = search_row(matrix, end_row * cols, middle_col + 1, cols - 1, target);
    return col < 0 ? -1 : end_row * cols + col;
}
