/* Count right-and-down paths with a one-dimensional dynamic-programming row. */
#include <cstdint>

extern "C" std::int64_t unique_paths(std::uint64_t rows, std::uint64_t columns) noexcept
{
    if (rows == 0 || columns == 0 || rows > 34 || columns > 34) return -1;
    const std::uint64_t width = rows < columns ? rows : columns;
    const std::uint64_t height = rows < columns ? columns : rows;
    std::int64_t paths[34]{};
    for (std::uint64_t column = 0; column < width; ++column) paths[column] = 1;
    for (std::uint64_t row = 1; row < height; ++row) {
        for (std::uint64_t column = 1; column < width; ++column) {
            paths[column] += paths[column - 1];
        }
    }
    return paths[width - 1];
}
