#include <stddef.h>
#include <stdint.h>

#define MAX_ROWS INT64_C(6)
#define MAX_COLS INT64_C(6)
#define MAX_BUDGET INT64_C(6)
#define MAX_STATES 252

int64_t grid_shortest_path_obstacle_elimination(const int64_t *values, size_t length) {
    if (values == NULL || length < 3 || length > 40) return -2;
    const int64_t rows = values[0];
    const int64_t columns = values[1];
    const int64_t budget = values[2];
    if (rows < 1 || rows > MAX_ROWS || columns < 1 || columns > MAX_COLS ||
        budget < 0 || budget > MAX_BUDGET ||
        length != (size_t)(3 + rows * columns)) return -2;

    const size_t cells_count = (size_t)(rows * columns);
    int64_t cells[36];
    for (size_t cell = 0; cell < cells_count; ++cell) {
        const int64_t value = values[3 + cell];
        if (value != 0 && value != 1) return -2;
        cells[cell] = value;
    }
    if (cells[0] != 0 || cells[cells_count - 1] != 0) return -2;

    const size_t stride = (size_t)(budget + 1);
    const size_t state_count = cells_count * stride;
    int64_t queue[MAX_STATES];
    int64_t distance[MAX_STATES];
    for (size_t state = 0; state < state_count; ++state) distance[state] = -1;
    size_t head = 0;
    size_t tail = 0;
    const size_t start = (size_t)budget;
    queue[tail++] = (int64_t)start;
    distance[start] = 0;

    while (head < tail) {
        const size_t state = (size_t)queue[head++];
        const size_t cell = state / stride;
        const int64_t remaining = (int64_t)(state % stride);
        if (cell == cells_count - 1) return distance[state];
        const int64_t row = (int64_t)(cell / (size_t)columns);
        const int64_t column = (int64_t)(cell % (size_t)columns);
        const int64_t next_rows[4] = {row - 1, row, row, row + 1};
        const int64_t next_columns[4] = {column, column - 1, column + 1, column};
        for (size_t direction = 0; direction < 4; ++direction) {
            const int64_t next_row = next_rows[direction];
            const int64_t next_column = next_columns[direction];
            if (next_row < 0 || next_row >= rows || next_column < 0 || next_column >= columns) continue;
            const size_t next_cell = (size_t)(next_row * columns + next_column);
            const int64_t next_remaining = remaining - cells[next_cell];
            if (next_remaining < 0) continue;
            const size_t next_state = next_cell * stride + (size_t)next_remaining;
            if (distance[next_state] != -1) continue;
            distance[next_state] = distance[state] + 1;
            queue[tail++] = (int64_t)next_state;
        }
    }
    return -1;
}
