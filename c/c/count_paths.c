/* Count four-neighbor vertex-simple grid paths by recursive DFS. */
#include <stddef.h>
#include <stdint.h>

static int64_t count_from(const int64_t *grid, uint32_t rows, uint32_t cols,
                          int row, int col, uint32_t visited)
{
    if (row < 0 || col < 0 || row >= (int)rows || col >= (int)cols) return 0;
    const uint32_t index = (uint32_t)row * cols + (uint32_t)col;
    if (grid[index] == 1 || (visited & (UINT32_C(1) << index)) != 0) return 0;
    if ((uint32_t)row == rows - 1 && (uint32_t)col == cols - 1) return 1;
    const uint32_t seen = visited | (UINT32_C(1) << index);
    int64_t count = 0;
    count += count_from(grid, rows, cols, row + 1, col, seen);
    count += count_from(grid, rows, cols, row - 1, col, seen);
    count += count_from(grid, rows, cols, row, col + 1, seen);
    count += count_from(grid, rows, cols, row, col - 1, seen);
    return count;
}

int64_t count_paths(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || values[0] < 1 || values[0] > 5 || values[1] < 1 || values[1] > 5) return -1;
    const uint32_t rows = (uint32_t)values[0], cols = (uint32_t)values[1];
    if (rows * cols > 25 || length != 2 + (size_t)rows * cols) return -1;
    for (size_t i = 2; i < length; ++i) if (values[i] != 0 && values[i] != 1) return -1;
    return count_from(values + 2, rows, cols, 0, 0, 0);
}
