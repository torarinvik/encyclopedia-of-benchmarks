#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ROWS = 80;
constexpr std::size_t MAX_COLUMNS = 80;
constexpr std::int64_t MAX_CELL_VALUE = 9999;
}

extern "C" std::int64_t problem82(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 3) return -1;
    const auto row_value = input[0];
    const auto column_value = input[1];
    if (row_value < 1 || row_value > static_cast<std::int64_t>(MAX_ROWS)
        || column_value < 1 || column_value > static_cast<std::int64_t>(MAX_COLUMNS)) return -1;
    const auto rows = static_cast<std::size_t>(row_value);
    const auto columns = static_cast<std::size_t>(column_value);
    if (length != 2 + rows * columns) return -1;
    for (std::size_t index = 2; index < length; ++index)
        if (input[index] < 0 || input[index] > MAX_CELL_VALUE) return -1;

    std::int64_t costs[MAX_ROWS]{};
    for (std::size_t row = 0; row < rows; ++row) costs[row] = input[2 + row * columns];
    for (std::size_t column = 1; column < columns; ++column) {
        const auto offset = 2 + column;
        for (std::size_t row = 0; row < rows; ++row)
            costs[row] += input[offset + row * columns];
        for (std::size_t row = 1; row < rows; ++row) {
            const auto from_above = costs[row - 1] + input[offset + row * columns];
            if (from_above < costs[row]) costs[row] = from_above;
        }
        for (std::size_t row = rows - 1; row > 0; --row) {
            const auto from_below = costs[row] + input[offset + (row - 1) * columns];
            if (from_below < costs[row - 1]) costs[row - 1] = from_below;
        }
    }
    auto best = costs[0];
    for (std::size_t row = 1; row < rows; ++row) if (costs[row] < best) best = costs[row];
    return best;
}
