#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_cells = 9;
int heuristic(int cell, int goal, int columns) {
    const int row = cell / columns, column = cell % columns;
    const int goal_row = goal / columns, goal_column = goal % columns;
    const int row_distance = row > goal_row ? row - goal_row : goal_row - row;
    const int column_distance = column > goal_column ? column - goal_column : goal_column - column;
    return row_distance + column_distance;
}
}

extern "C" std::int64_t greedy_best_first(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 7 || length > 9) return -1;
    const auto row_value = values[0], column_value = values[1];
    if (row_value < 1 || row_value > 3 || column_value < 1 || column_value > 3) return -1;
    const int rows = static_cast<int>(row_value), columns = static_cast<int>(column_value);
    if (length != 6 + static_cast<std::size_t>(rows)) return -1;
    const auto start_row = values[2], start_column = values[3], goal_row = values[4], goal_column = values[5];
    if (start_row < 0 || start_row >= rows || goal_row < 0 || goal_row >= rows ||
        start_column < 0 || start_column >= columns || goal_column < 0 || goal_column >= columns) return -1;
    int masks[3]{};
    for (int row = 0; row < rows; ++row) {
        const auto mask = values[6 + static_cast<std::size_t>(row)];
        if (mask < 0 || mask >= (1 << columns)) return -1;
        masks[row] = static_cast<int>(mask);
    }
    const int start = static_cast<int>(start_row * columns + start_column);
    const int goal = static_cast<int>(goal_row * columns + goal_column);
    if ((masks[start / columns] & (1 << (start % columns))) ||
        (masks[goal / columns] & (1 << (goal % columns)))) return -1;

    int opened[max_cells]{}, parent[max_cells], closed[max_cells]{}, in_open[max_cells]{};
    for (int cell = 0; cell < max_cells; ++cell) parent[cell] = -1;
    int open_count = 1, found = 0;
    opened[0] = start;
    in_open[start] = 1;
    while (open_count > 0) {
        for (int index = 1; index < open_count; ++index) {
            const int current = opened[index];
            int position = index;
            while (position > 0 && heuristic(opened[position - 1], goal, columns) > heuristic(current, goal, columns)) {
                opened[position] = opened[position - 1];
                --position;
            }
            opened[position] = current;
        }
        const int current = opened[0];
        for (int index = 1; index < open_count; ++index) opened[index - 1] = opened[index];
        --open_count;
        in_open[current] = 0;
        if (current == goal) { found = 1; break; }
        closed[current] = 1;
        const int row = current / columns, column = current % columns;
        const int next_rows[4] = {row - 1, row, row + 1, row};
        const int next_columns[4] = {column, column - 1, column, column + 1};
        for (int direction = 0; direction < 4; ++direction) {
            const int next_row = next_rows[direction], next_column = next_columns[direction];
            if (next_row < 0 || next_row >= rows || next_column < 0 || next_column >= columns) continue;
            const int child = next_row * columns + next_column;
            if ((masks[next_row] & (1 << next_column)) || closed[child] || in_open[child]) continue;
            parent[child] = current;
            opened[open_count++] = child;
            in_open[child] = 1;
        }
    }
    int path[max_cells], path_count = 0;
    if (found) {
        for (int current = goal; current >= 0 && path_count < max_cells; current = parent[current]) path[path_count++] = current;
    } else {
        path[path_count++] = start;
    }
    std::uint64_t packed = 0;
    for (int index = 0; index < path_count; ++index)
        packed |= static_cast<std::uint64_t>(path[path_count - 1 - index] + 1) << (4 * index);
    return static_cast<std::int64_t>((static_cast<std::uint64_t>(path_count) << 36) | packed);
}
