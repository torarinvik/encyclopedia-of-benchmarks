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

    uint64_t paths[MAX_COLUMNS] = {0};
    paths[0] = 1;
    uint64_t cells_seen = 0;
    uint64_t left = 0;
    size_t index = 2;
    while (index < length) {
        left = 0;
        for (size_t column = 0; column < columns; ++column) {
            const uint64_t obstacle = (uint64_t)input[index++];
            cells_seen |= obstacle;
            left = obstacle == 0 ? left + paths[column] : 0;
            paths[column] = left;
        }
    }
    if (cells_seen > 1) return -1;
    return (int64_t)left;
}
