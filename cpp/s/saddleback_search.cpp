// Top-right staircase search for a strictly increasing integer matrix.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_dimension = 32;
constexpr std::int64_t i32_min = -2147483648LL;
constexpr std::int64_t i32_max = 2147483647LL;
}

extern "C" std::int64_t saddleback_search(const std::int64_t *values,
                                           std::size_t length) noexcept {
    if (values == nullptr || length < 3) return -1;
    const auto rows_value = values[0], columns_value = values[1], target = values[2];
    if (rows_value <= 0 || rows_value > max_dimension ||
        columns_value <= 0 || columns_value > max_dimension ||
        target < i32_min || target > i32_max) return -1;
    const auto rows = static_cast<std::size_t>(rows_value);
    const auto columns = static_cast<std::size_t>(columns_value);
    const auto cells = rows * columns;
    if (length != 3 + cells) return -1;
    const auto *matrix = values + 3;
    for (std::size_t index = 0; index < cells; ++index) {
        if (matrix[index] < i32_min || matrix[index] > i32_max) return -1;
    }

    std::size_t row = 0, column = columns - 1;
    while (row < rows) {
        const auto value = matrix[row * columns + column];
        if (value == target)
            return static_cast<std::int64_t>(row * columns + column + 1);
        if (value < target) {
            ++row;
        } else if (column == 0) {
            break;
        } else {
            --column;
        }
    }
    return 0;
}
