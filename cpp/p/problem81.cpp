#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_DIMENSION = 80;
constexpr std::int64_t MAX_CELL_VALUE = 9999;
}

extern "C" std::int64_t problem81(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 1) return -1;
    const auto dimension_value = input[0];
    if (dimension_value < 1 || dimension_value > static_cast<std::int64_t>(MAX_DIMENSION)) return -1;
    const auto dimension = static_cast<std::size_t>(dimension_value);
    if (length != 1 + dimension * dimension) return -1;
    for (std::size_t index = 1; index < length; ++index)
        if (input[index] < 0 || input[index] > MAX_CELL_VALUE) return -1;

    std::array<std::int64_t, MAX_DIMENSION> costs{};
    costs[0] = input[1];
    for (std::size_t column = 1; column < dimension; ++column)
        costs[column] = costs[column - 1] + input[1 + column];
    for (std::size_t row = 1; row < dimension; ++row) {
        const auto row_offset = 1 + row * dimension;
        costs[0] += input[row_offset];
        for (std::size_t column = 1; column < dimension; ++column) {
            const auto above = costs[column];
            const auto left = costs[column - 1];
            costs[column] = (above < left ? above : left) + input[row_offset + column];
        }
    }
    return costs[dimension - 1];
}
