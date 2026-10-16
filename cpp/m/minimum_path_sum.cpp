#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" std::int64_t minimum_path_sum(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 2 || length > 66) return std::numeric_limits<std::int64_t>::min();
    const std::int64_t row_value = values[0], column_value = values[1];
    if (row_value < 1 || row_value > 8 || column_value < 1 || column_value > 8)
        return std::numeric_limits<std::int64_t>::min();
    const std::size_t rows = static_cast<std::size_t>(row_value);
    const std::size_t columns = static_cast<std::size_t>(column_value);
    if (length != 2 + rows * columns) return std::numeric_limits<std::int64_t>::min();
    std::int64_t costs[8]{};
    for (std::size_t row = 0; row < rows; ++row) {
        for (std::size_t column = 0; column < columns; ++column) {
            const std::int64_t cell = values[2 + row * columns + column];
            if (cell < 0 || cell > 1000) return std::numeric_limits<std::int64_t>::min();
            if (row == 0 && column == 0) costs[column] = cell;
            else if (row == 0) costs[column] = costs[column - 1] + cell;
            else if (column == 0) costs[column] += cell;
            else costs[column] = (costs[column - 1] < costs[column] ? costs[column - 1] : costs[column]) + cell;
        }
    }
    return costs[columns - 1];
}
