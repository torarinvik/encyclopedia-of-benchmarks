/* Return the largest four-connected component of cells equal to one. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ROWS 16
#define MAX_COLUMNS 16
#define MAX_CELLS (MAX_ROWS * MAX_COLUMNS)

int64_t max_area_of_island(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || input[0] < 0 || input[0] > MAX_ROWS ||
        input[1] < 0 || input[1] > MAX_COLUMNS) return -1;
    const size_t rows = (size_t)input[0];
    const size_t columns = (size_t)input[1];
    const size_t cells = rows * columns;
    if (length != cells + 2) return -1;
    for (size_t i = 0; i < cells; ++i) {
        if (input[2 + i] != 0 && input[2 + i] != 1) return -1;
    }

    uint8_t visited[MAX_CELLS] = {0};
    size_t stack[MAX_CELLS];
    size_t maximum_area = 0;
    for (size_t start = 0; start < cells; ++start) {
        if (input[2 + start] == 0 || visited[start]) continue;
        size_t top = 0, area = 0;
        visited[start] = 1;
        stack[top++] = start;
        while (top != 0) {
            const size_t current = stack[--top];
            ++area;
            const size_t row = current / columns;
            const size_t column = current % columns;
            size_t neighbor;
            if (row > 0) {
                neighbor = current - columns;
                if (!visited[neighbor] && input[2 + neighbor] == 1) { visited[neighbor] = 1; stack[top++] = neighbor; }
            }
            if (row + 1 < rows) {
                neighbor = current + columns;
                if (!visited[neighbor] && input[2 + neighbor] == 1) { visited[neighbor] = 1; stack[top++] = neighbor; }
            }
            if (column > 0) {
                neighbor = current - 1;
                if (!visited[neighbor] && input[2 + neighbor] == 1) { visited[neighbor] = 1; stack[top++] = neighbor; }
            }
            if (column + 1 < columns) {
                neighbor = current + 1;
                if (!visited[neighbor] && input[2 + neighbor] == 1) { visited[neighbor] = 1; stack[top++] = neighbor; }
            }
        }
        if (area > maximum_area) maximum_area = area;
    }
    return (int64_t)maximum_area;
}
