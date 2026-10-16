#include <stddef.h>
#include <stdint.h>

#define MAX_ROWS 15
#define MAX_VALUES (MAX_ROWS * (MAX_ROWS + 1) / 2)
#define VALUE_LIMIT INT64_C(1000000)

int64_t problem18(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_VALUES + 1) return -1;
    const int64_t rows = input[0];
    if (rows < 1 || rows > MAX_ROWS || length != (size_t)(rows * (rows + 1) / 2) + 1) return -1;
    int64_t best[MAX_VALUES];
    const size_t value_count = length - 1;
    for (size_t index = 0; index < value_count; ++index) {
        const int64_t value = input[index + 1];
        if (value < 0 || value > VALUE_LIMIT) return -1;
        best[index] = value;
    }
    for (int64_t row = rows - 1; row > 0; --row) {
        const size_t parent_start = (size_t)((row - 1) * row / 2);
        const size_t child_start = (size_t)(row * (row + 1) / 2);
        for (int64_t column = 0; column < row; ++column) {
            const size_t parent = parent_start + (size_t)column;
            const size_t child = child_start + (size_t)column;
            const int64_t left = best[child];
            const int64_t right = best[child + 1];
            best[parent] += left > right ? left : right;
        }
    }
    return best[0];
}
