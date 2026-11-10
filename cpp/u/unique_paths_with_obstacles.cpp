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

    std::uint64_t paths[max_columns]{};
    paths[0] = 1;
    std::uint64_t cells_seen = 0;
    std::uint64_t left = 0;
    std::size_t index = 2;
    while (index < length) {
        left = 0;
        for (std::size_t column = 0; column < columns; ++column) {
            const std::uint64_t obstacle = static_cast<std::uint64_t>(input[index++]);
            cells_seen |= obstacle;
            left = obstacle == 0 ? left + paths[column] : 0;
            paths[column] = left;
        }
    }
    if (cells_seen > 1) return -1;
    return static_cast<std::int64_t>(left);
}
