// Count four-neighbor vertex-simple grid paths by recursive DFS.
#include <cstddef>
#include <cstdint>

static std::int64_t count_from(const std::int64_t *grid, std::uint32_t rows,
                              std::uint32_t cols, int row, int col,
                              std::uint32_t visited)
{
    if (row < 0 || col < 0 || row >= static_cast<int>(rows) || col >= static_cast<int>(cols)) return 0;
    const auto index = static_cast<std::uint32_t>(row) * cols + static_cast<std::uint32_t>(col);
    const auto mask = std::uint32_t{1} << index;
    if (grid[index] == 1 || (visited & mask) != 0) return 0;
    if (static_cast<std::uint32_t>(row) == rows - 1 && static_cast<std::uint32_t>(col) == cols - 1) return 1;
    const auto seen = visited | mask;
    std::int64_t count = 0;
    count += count_from(grid, rows, cols, row + 1, col, seen);
    count += count_from(grid, rows, cols, row - 1, col, seen);
    count += count_from(grid, rows, cols, row, col + 1, seen);
    count += count_from(grid, rows, cols, row, col - 1, seen);
    return count;
}

extern "C" std::int64_t count_paths(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 3 || values[0] < 1 || values[0] > 5 || values[1] < 1 || values[1] > 5) return -1;
    const auto rows = static_cast<std::uint32_t>(values[0]);
    const auto cols = static_cast<std::uint32_t>(values[1]);
    if (rows * cols > 25 || length != 2 + static_cast<std::size_t>(rows) * cols) return -1;
    for (std::size_t i = 2; i < length; ++i) if (values[i] != 0 && values[i] != 1) return -1;
    return count_from(values + 2, rows, cols, 0, 0, 0);
}
