#include <stddef.h>
#include <stdint.h>

static void flood(const int64_t *cells, uint8_t *visited, int rows, int cols, int row, int col)
{
    if (row < 0 || col < 0 || row >= rows || col >= cols) return;
    const int index = row * cols + col;
    if (cells[index] != 1 || visited[index]) return;
    visited[index] = 1;
    flood(cells, visited, rows, cols, row + 1, col);
    flood(cells, visited, rows, cols, row - 1, col);
    flood(cells, visited, rows, cols, row, col + 1);
    flood(cells, visited, rows, cols, row, col - 1);
}

int64_t number_of_islands(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || values[0] < 1 || values[0] > 16 || values[1] < 1 || values[1] > 16) return -1;
    const int rows = (int)values[0], cols = (int)values[1];
    if (length != (size_t)(2 + rows * cols)) return -1;
    const int64_t *cells = values + 2;
    for (int i = 0; i < rows * cols; ++i) if (cells[i] != 0 && cells[i] != 1) return -1;
    uint8_t visited[256] = {0};
    int64_t count = 0;
    for (int row = 0; row < rows; ++row) for (int col = 0; col < cols; ++col) {
        const int index = row * cols + col;
        if (cells[index] == 1 && !visited[index]) {
            ++count;
            flood(cells, visited, rows, cols, row, col);
        }
    }
    return count;
}
