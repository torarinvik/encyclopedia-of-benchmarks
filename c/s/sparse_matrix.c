/* Return whether strictly more than half of a matrix's entries are zero. */
#include <stddef.h>
#include <stdint.h>

#define SPARSE_MATRIX_MAX_INPUT_LENGTH 4099
#define SPARSE_MATRIX_MIN_CELL INT32_MIN
#define SPARSE_MATRIX_MAX_CELL INT32_MAX

int64_t sparse_matrix(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > SPARSE_MATRIX_MAX_INPUT_LENGTH) return -1;
    const int64_t rows_value = values[0], columns_value = values[1];
    if (rows_value < 1 || rows_value > 64 || columns_value < 1 || columns_value > 64) return -1;
    const size_t rows = (size_t)rows_value, columns = (size_t)columns_value;
    const size_t cells = rows * columns;
    if (length != 2 + cells) return -1;
    int64_t zero_count = 0;
    for (size_t index = 0; index < cells; ++index) {
        const int64_t value = values[2 + index];
        if (value < SPARSE_MATRIX_MIN_CELL || value > SPARSE_MATRIX_MAX_CELL) return -1;
        if (value == 0) ++zero_count;
    }
    return zero_count > (int64_t)(cells / 2) ? 1 : 0;
}
