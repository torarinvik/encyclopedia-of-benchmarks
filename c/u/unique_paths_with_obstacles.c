/* Count right/down paths through a packed obstacle grid. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ROWS 20
#define MAX_COLUMNS 20

int64_t unique_paths_with_obstacles(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2) return -1;
    const int64_t rows_value = input[0], columns_value = input[1];
    if (rows_value < 1 || rows_value > MAX_ROWS ||
        columns_value < 1 || columns_value > MAX_COLUMNS) return -1;
    const size_t rows = (size_t)rows_value, columns = (size_t)columns_value;
    if (length != 2 + rows * columns) return -1;
    for (size_t index = 2; index < length; ++index)
        if (input[index] != 0 && input[index] != 1) return -1;

    int64_t paths[MAX_COLUMNS] = {0};
    paths[0] = 1;
    for (size_t row = 0; row < rows; ++row) {
        for (size_t column = 0; column < columns; ++column) {
            const int64_t obstacle = input[2 + row * columns + column];
            if (obstacle == 1) paths[column] = 0;
            else if (column != 0) paths[column] += paths[column - 1];
        }
    }
    return paths[columns - 1];
}
