// Return the total allowable increase while preserving row and column skylines.
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t max_increase_keeping_skyline(const std::int64_t *values, std::size_t length)
{
    constexpr std::size_t max_grid_size = 50;
    if (values == nullptr || length < 2 || length > 1 + max_grid_size * max_grid_size) return -1;
    if (values[0] < 2 || values[0] > static_cast<std::int64_t>(max_grid_size)) return -1;
    const auto size = static_cast<std::size_t>(values[0]);
    if (length != 1 + size * size) return -1;

    std::array<std::int64_t, max_grid_size> row_max{};
    std::array<std::int64_t, max_grid_size> column_max{};
    for (std::size_t row = 0; row < size; ++row) {
        for (std::size_t column = 0; column < size; ++column) {
            const auto height = values[1 + row * size + column];
            if (height < 0 || height > 100) return -1;
            if (height > row_max[row]) row_max[row] = height;
            if (height > column_max[column]) column_max[column] = height;
        }
    }

    std::int64_t total = 0;
    for (std::size_t row = 0; row < size; ++row) {
        for (std::size_t column = 0; column < size; ++column) {
            const auto height = values[1 + row * size + column];
            const auto skyline = row_max[row] < column_max[column]
                ? row_max[row] : column_max[column];
            total += skyline - height;
        }
    }
    return total;
}
