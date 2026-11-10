// Return the total allowable increase while preserving row and column skylines.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t max_increase_keeping_skyline(const std::int64_t *values, std::size_t length)
{
    constexpr std::size_t max_grid_size = 50;
    if (values == nullptr || length < 2 || length > 1 + max_grid_size * max_grid_size) return -1;
    if (values[0] < 2 || values[0] > static_cast<std::int64_t>(max_grid_size)) return -1;
    const auto size = static_cast<std::size_t>(values[0]);
    if (length != 1 + size * size) return -1;

    std::uint8_t row_max[max_grid_size] = {0};
    std::uint8_t column_max[max_grid_size] = {0};
    std::uint64_t tallest = 0;
    std::uint32_t height_sum = 0;
    for (std::size_t row = 0; row < size; ++row) {
        std::uint8_t row_tallest = 0;
        std::size_t start = 1 + row * size;
        for (std::size_t column = 0; column < size; ++column) {
            std::uint64_t value = static_cast<std::uint64_t>(values[start + column]);
            tallest = value > tallest ? value : tallest;
            height_sum += static_cast<std::uint32_t>(value);
            std::uint8_t height = static_cast<std::uint8_t>(value);
            row_tallest = height > row_tallest ? height : row_tallest;
            column_max[column] = height > column_max[column] ? height : column_max[column];
        }
        row_max[row] = row_tallest;
    }
    if (tallest > 100) return -1;

    std::uint32_t skyline_sum = 0;
    if (size <= 10) {
        for (std::size_t row = 0; row < size; ++row) {
            std::uint8_t row_height = row_max[row];
            for (std::size_t column = 0; column < size; ++column) {
                std::uint8_t column_height = column_max[column];
                skyline_sum += static_cast<std::uint32_t>((row_height < column_height ? row_height : column_height));
            }
        }
    } else {
        std::uint8_t row_counts[101] = {0};
        std::uint8_t column_counts[101] = {0};
        std::uint8_t lowest = 100;
        for (std::size_t index = 0; index < size; ++index) {
            lowest = row_max[index] < lowest ? row_max[index] : lowest;
            lowest = column_max[index] < lowest ? column_max[index] : lowest;
            row_counts[row_max[index]]++;
            column_counts[column_max[index]]++;
        }
        std::uint32_t rows_above = static_cast<std::uint32_t>(size);
        std::uint32_t columns_above = static_cast<std::uint32_t>(size);
        skyline_sum = rows_above * columns_above * lowest;
        for (std::size_t height = lowest; height < tallest; ++height) {
            rows_above -= row_counts[height];
            columns_above -= column_counts[height];
            skyline_sum += rows_above * columns_above;
        }
    }
    return static_cast<std::int64_t>((skyline_sum - height_sum));
}
