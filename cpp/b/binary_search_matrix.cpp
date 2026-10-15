// Recursive row search matching the pinned matrix-search source.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_dimension = 32;

std::int64_t search_row(const std::int64_t *values, std::size_t base,
                       std::int64_t lower, std::int64_t upper,
                       std::int64_t target) noexcept {
    const auto middle = (lower + upper) / 2;
    const auto value = values[base + static_cast<std::size_t>(middle)];
    if (value == target) return middle;
    if (lower >= upper) return -1;
    if (value < target) return search_row(values, base, middle + 1, upper, target);
    return search_row(values, base, lower, middle - 1, target);
}
}

extern "C" std::int64_t binary_search_matrix(const std::int64_t *values,
                                                std::size_t length) noexcept {
    if (values == nullptr || length < 3) return -1;
    const auto rows_value = values[0], columns_value = values[1], target = values[2];
    if (rows_value <= 0 || rows_value > 32 || columns_value <= 0 || columns_value > 32) return -1;
    const auto rows = static_cast<std::size_t>(rows_value);
    const auto columns = static_cast<std::size_t>(columns_value);
    if (length != 3 + rows * columns) return -1;
    const auto *matrix = values + 3;
    if (matrix[0] == target) return 0;
    for (std::size_t row = 0; row < rows && matrix[row * columns] < target; ++row) {
        const auto column = search_row(matrix, row * columns, 0,
                                       static_cast<std::int64_t>(columns) - 1, target);
        if (column != -1) return static_cast<std::int64_t>(row * columns) + column;
    }
    return -1;
}
