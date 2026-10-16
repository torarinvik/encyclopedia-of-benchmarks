#include <stddef.h>
#include <stdint.h>

#define MAX_CELLS 9

static int heuristic(int cell, int goal, int columns) {
    int row = cell / columns, column = cell % columns;
    int goal_row = goal / columns, goal_column = goal % columns;
    int row_distance = row > goal_row ? row - goal_row : goal_row - row;
    int column_distance = column > goal_column ? column - goal_column : goal_column - column;
    return row_distance + column_distance;
}

int64_t greedy_best_first(const int64_t *values, size_t length) {
    if (values == NULL || length < 7 || length > 9) return -1;
    int64_t row_value = values[0], column_value = values[1];
    if (row_value < 1 || row_value > 3 || column_value < 1 || column_value > 3) return -1;
    int rows = (int)row_value, columns = (int)column_value;
    if (length != 6 + (size_t)rows) return -1;
    int64_t start_row = values[2], start_column = values[3], goal_row = values[4], goal_column = values[5];
    if (start_row < 0 || start_row >= rows || goal_row < 0 || goal_row >= rows ||
        start_column < 0 || start_column >= columns || goal_column < 0 || goal_column >= columns) return -1;
    int masks[3] = {0};
    for (int row = 0; row < rows; ++row) {
        int64_t mask = values[6 + (size_t)row];
        if (mask < 0 || mask >= (1 << columns)) return -1;
        masks[row] = (int)mask;
    }
    const int start = (int)(start_row * columns + start_column);
    const int goal = (int)(goal_row * columns + goal_column);
    if ((masks[start / columns] & (1 << (start % columns))) ||
        (masks[goal / columns] & (1 << (goal % columns)))) return -1;

    int opened[MAX_CELLS] = {0}, parent[MAX_CELLS], closed[MAX_CELLS] = {0}, in_open[MAX_CELLS] = {0};
    for (int cell = 0; cell < MAX_CELLS; ++cell) parent[cell] = -1;
    int open_count = 1, found = 0;
    opened[0] = start;
    in_open[start] = 1;
    while (open_count > 0) {
        for (int index = 1; index < open_count; ++index) {
            int current = opened[index], position = index;
            while (position > 0 && heuristic(opened[position - 1], goal, columns) > heuristic(current, goal, columns)) {
                opened[position] = opened[position - 1];
                --position;
            }
            opened[position] = current;
        }
        int current = opened[0];
        for (int index = 1; index < open_count; ++index) opened[index - 1] = opened[index];
        --open_count;
        in_open[current] = 0;
        if (current == goal) { found = 1; break; }
        closed[current] = 1;
        int row = current / columns, column = current % columns;
        int next_rows[4] = {row - 1, row, row + 1, row};
        int next_columns[4] = {column, column - 1, column, column + 1};
        for (int direction = 0; direction < 4; ++direction) {
            int next_row = next_rows[direction], next_column = next_columns[direction];
            if (next_row < 0 || next_row >= rows || next_column < 0 || next_column >= columns) continue;
            int child = next_row * columns + next_column;
            if ((masks[next_row] & (1 << next_column)) || closed[child] || in_open[child]) continue;
            parent[child] = current;
            opened[open_count++] = child;
            in_open[child] = 1;
        }
    }

    int path[MAX_CELLS], path_count = 0;
    if (found) {
        for (int current = goal; current >= 0 && path_count < MAX_CELLS; current = parent[current]) path[path_count++] = current;
    } else {
        path[path_count++] = start;
    }
    uint64_t packed = 0;
    for (int index = 0; index < path_count; ++index)
        packed |= (uint64_t)(path[path_count - 1 - index] + 1) << (4 * index);
    return (int64_t)(((uint64_t)path_count << 36) | packed);
}
