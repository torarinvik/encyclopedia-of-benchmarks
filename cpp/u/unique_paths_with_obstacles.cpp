// Count right/down paths through a packed obstacle grid.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_rows = 20;
constexpr std::int64_t max_columns = 20;
}

extern "C" std::int64_t unique_paths_with_obstacles(const std::int64_t *input,
                                                     std::size_t length) noexcept {
    if (input == nullptr || length < 2) return -1;
    const auto rows_value = input[0];
    const auto columns_value = input[1];
    if (rows_value < 1 || rows_value > max_rows ||
        columns_value < 1 || columns_value > max_columns) return -1;
    const auto rows = static_cast<std::size_t>(rows_value);
    const auto columns = static_cast<std::size_t>(columns_value);
    if (length != 2 + rows * columns) return -1;
    for (std::size_t index = 2; index < length; ++index)
        if (input[index] != 0 && input[index] != 1) return -1;

    std::int64_t paths[max_columns]{};
    paths[0] = 1;
    for (std::size_t row = 0; row < rows; ++row) {
        for (std::size_t column = 0; column < columns; ++column) {
            const auto obstacle = input[2 + row * columns + column];
            if (obstacle == 1) paths[column] = 0;
            else if (column != 0) paths[column] += paths[column - 1];
        }
    }
    return paths[columns - 1];
}
