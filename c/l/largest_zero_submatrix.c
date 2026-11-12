#include <stddef.h>
#include <stdint.h>

enum { MAX_ROWS = 16, MAX_COLUMNS = 16 };

int64_t largest_zero_submatrix(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2u || length > 259u) return -1;
    const int64_t rows_value = input[0], columns_value = input[1];
    if (rows_value < 1 || rows_value > MAX_ROWS || columns_value < 1 || columns_value > MAX_COLUMNS)
        return -1;
    const size_t rows = (size_t)rows_value, columns = (size_t)columns_value;
    if (length != 2u + rows * columns) return -1;
    for (size_t index = 2u; index < length; ++index)
        if (input[index] != 0 && input[index] != 1) return -1;

    int64_t last_one[MAX_COLUMNS];
    int left[MAX_COLUMNS], right[MAX_COLUMNS], stack[MAX_COLUMNS];
    for (size_t column = 0; column < columns; ++column) last_one[column] = -1;
    int64_t best = 0;
    for (size_t row = 0; row < rows; ++row) {
        for (size_t column = 0; column < columns; ++column)
            if (input[2u + row * columns + column] == 1) last_one[column] = (int64_t)row;

        size_t top = 0;
        for (size_t column = 0; column < columns; ++column) {
            while (top > 0u && last_one[stack[top - 1u]] <= last_one[column]) --top;
            left[column] = top == 0u ? -1 : stack[top - 1u];
            stack[top++] = (int)column;
        }
        top = 0;
        for (size_t cursor = columns; cursor > 0u; --cursor) {
            const size_t column = cursor - 1u;
            while (top > 0u && last_one[stack[top - 1u]] <= last_one[column]) --top;
            right[column] = top == 0u ? (int)columns : stack[top - 1u];
            stack[top++] = (int)column;
        }
        for (size_t column = 0; column < columns; ++column) {
            const int64_t height = (int64_t)row - last_one[column];
            const int64_t width = right[column] - left[column] - 1;
            const int64_t area = height * width;
            if (area > best) best = area;
        }
    }
    return best;
}
