#include <stddef.h>
#include <stdint.h>

#define MAX_ROWS 32
#define MAX_COLUMNS 32
#define INF_COST UINT32_C(65536)

int64_t minimum_path_cost_in_grid(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2) return -1;
    if (input[0] < 1 || input[0] > MAX_ROWS || input[1] < 1 || input[1] > MAX_COLUMNS) return -1;
    const size_t rows = (size_t)input[0];
    const size_t columns = (size_t)input[1];
    const size_t cells = rows * columns;
    const size_t move_offset = 2 + cells;
    if (length != move_offset + cells * columns) return -1;
    for (size_t index = 0; index < cells; ++index)
        if (input[2 + index] < 0 || input[2 + index] >= (int64_t)cells) return -1;
    for (size_t index = 0; index < cells * columns; ++index)
        if (input[move_offset + index] < 1 || input[move_offset + index] > 100) return -1;

    uint32_t costs[MAX_COLUMNS] = {0};
    uint32_t next_costs[MAX_COLUMNS];
    for (size_t row = 0; row + 1 < rows; ++row) {
        for (size_t target = 0; target < columns; ++target) next_costs[target] = INF_COST;
        for (size_t column = 0; column < columns; ++column) {
            const size_t grid_index = 2 + row * columns + column;
            const size_t value = (size_t)input[grid_index];
            const uint32_t base = costs[column] + (uint32_t)value;
            for (size_t target = 0; target < columns; ++target) {
                const uint32_t candidate = base + (uint32_t)input[move_offset + value * columns + target];
                next_costs[target] = candidate < next_costs[target] ? candidate : next_costs[target];
            }
        }
        for (size_t column = 0; column < columns; ++column) costs[column] = next_costs[column];
    }
    uint32_t minimum = INF_COST;
    const size_t last_row = 2 + (rows - 1) * columns;
    for (size_t column = 0; column < columns; ++column) {
        const uint32_t candidate = costs[column] + (uint32_t)input[last_row + column];
        if (candidate < minimum) minimum = candidate;
    }
    return minimum;
}
