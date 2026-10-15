#include <cstddef>
#include <cstdint>

static void flood(const int64_t* cells, bool* visited, int rows, int cols, int row, int col) {
    if (row < 0 || col < 0 || row >= rows || col >= cols) return;
    const int index = row * cols + col;
    if (cells[index] != 1 || visited[index]) return;
    visited[index] = true;
    for (int dr = -1; dr <= 1; ++dr)
        for (int dc = -1; dc <= 1; ++dc)
            if (dr != 0 || dc != 0) flood(cells, visited, rows, cols, row + dr, col + dc);
}

extern "C" int64_t count_islands_in_matrix(const int64_t* values, size_t length) {
    if (values == nullptr || length < 3 || values[0] < 1 || values[0] > 16 || values[1] < 1 || values[1] > 16) return -1;
    const int rows = static_cast<int>(values[0]), cols = static_cast<int>(values[1]);
    if (length != static_cast<size_t>(2 + rows * cols)) return -1;
    for (size_t i = 2; i < length; ++i) if (values[i] != 0 && values[i] != 1) return -1;
    bool visited[256] = {};
    int64_t count = 0;
    for (int row = 0; row < rows; ++row) {
        for (int col = 0; col < cols; ++col) {
            const int index = row * cols + col;
            if (values[2 + index] == 1 && !visited[index]) {
                ++count;
                flood(values + 2, visited, rows, cols, row, col);
            }
        }
    }
    return count;
}
