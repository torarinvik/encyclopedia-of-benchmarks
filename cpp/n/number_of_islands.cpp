#include <cstddef>
#include <cstdint>

static void flood(const std::int64_t* cells, bool* visited, int rows, int cols, int row, int col) {
    if (row < 0 || col < 0 || row >= rows || col >= cols) return;
    const int index = row * cols + col;
    if (cells[index] != 1 || visited[index]) return;
    visited[index] = true;
    flood(cells, visited, rows, cols, row + 1, col);
    flood(cells, visited, rows, cols, row - 1, col);
    flood(cells, visited, rows, cols, row, col + 1);
    flood(cells, visited, rows, cols, row, col - 1);
}

extern "C" std::int64_t number_of_islands(const std::int64_t* values, std::size_t length) {
    if (values == nullptr || length < 3 || values[0] < 1 || values[0] > 16 || values[1] < 1 || values[1] > 16) return -1;
    const int rows = static_cast<int>(values[0]), cols = static_cast<int>(values[1]);
    if (length != static_cast<std::size_t>(2 + rows * cols)) return -1;
    const auto* cells = values + 2;
    for (int i = 0; i < rows * cols; ++i) if (cells[i] != 0 && cells[i] != 1) return -1;
    bool visited[256] = {};
    std::int64_t count = 0;
    for (int row = 0; row < rows; ++row) for (int col = 0; col < cols; ++col) {
        const int index = row * cols + col;
        if (cells[index] == 1 && !visited[index]) {
            ++count;
            flood(cells, visited, rows, cols, row, col);
        }
    }
    return count;
}
