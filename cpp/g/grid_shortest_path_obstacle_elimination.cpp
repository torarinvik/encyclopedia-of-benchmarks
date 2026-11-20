#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxDimension = 6;
constexpr std::int64_t kMaxBudget = 6;
constexpr std::size_t kMaxStates = 252;
}

extern "C" std::int64_t grid_shortest_path_obstacle_elimination(
    const std::int64_t* values, std::size_t length) {
    if (values == nullptr || length < 3 || length > 40) return -2;
    const std::int64_t rows = values[0];
    const std::int64_t columns = values[1];
    const std::int64_t budget = values[2];
    if (rows < 1 || rows > kMaxDimension || columns < 1 || columns > kMaxDimension ||
        budget < 0 || budget > kMaxBudget ||
        length != static_cast<std::size_t>(3 + rows * columns)) return -2;

    const std::size_t cell_count = static_cast<std::size_t>(rows * columns);
    std::array<std::int64_t, 36> cells{};
    for (std::size_t cell = 0; cell < cell_count; ++cell) {
        const auto value = values[3 + cell];
        if (value != 0 && value != 1) return -2;
        cells[cell] = value;
    }
    if (cells[0] != 0 || cells[cell_count - 1] != 0) return -2;

    const std::size_t stride = static_cast<std::size_t>(budget + 1);
    std::array<std::int64_t, kMaxStates> queue{};
    std::array<std::int64_t, kMaxStates> distance{};
    distance.fill(-1);
    std::size_t head = 0;
    std::size_t tail = 0;
    const std::size_t start = static_cast<std::size_t>(budget);
    queue[tail++] = static_cast<std::int64_t>(start);
    distance[start] = 0;

    while (head < tail) {
        const auto state = static_cast<std::size_t>(queue[head++]);
        const std::size_t cell = state / stride;
        const auto remaining = static_cast<std::int64_t>(state % stride);
        if (cell == cell_count - 1) return distance[state];
        const auto row = static_cast<std::int64_t>(cell / static_cast<std::size_t>(columns));
        const auto column = static_cast<std::int64_t>(cell % static_cast<std::size_t>(columns));
        const std::array<std::int64_t, 4> next_rows{row - 1, row, row, row + 1};
        const std::array<std::int64_t, 4> next_columns{column, column - 1, column + 1, column};
        for (std::size_t direction = 0; direction < 4; ++direction) {
            const auto next_row = next_rows[direction];
            const auto next_column = next_columns[direction];
            if (next_row < 0 || next_row >= rows || next_column < 0 || next_column >= columns) continue;
            const auto next_cell = static_cast<std::size_t>(next_row * columns + next_column);
            const auto next_remaining = remaining - cells[next_cell];
            if (next_remaining < 0) continue;
            const std::size_t next_state = next_cell * stride + static_cast<std::size_t>(next_remaining);
            if (distance[next_state] != -1) continue;
            distance[next_state] = distance[state] + 1;
            queue[tail++] = static_cast<std::int64_t>(next_state);
        }
    }
    return -1;
}
