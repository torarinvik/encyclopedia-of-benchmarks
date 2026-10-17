#include <stddef.h>
#include <stdint.h>

#define GRID_ROWS 8
#define GRID_COLS 7
#define GRID_CELLS (GRID_ROWS * GRID_COLS)
#define INPUT_WORDS (1 + GRID_CELLS)
#define OUTPUT_BYTES (4 * INPUT_WORDS)
#define START_INDEX (1 * GRID_COLS + 1)
#define TARGET_INDEX (6 * GRID_COLS + 5)

static int solve_maze(uint8_t *grid, int row, int col, int strategy) {
    if (grid[TARGET_INDEX] == 2) return 1;
    const size_t index = (size_t)(row * GRID_COLS + col);
    if (grid[index] != 0) return 0;
    grid[index] = 2;

    if (strategy == 0) {
        if (solve_maze(grid, row + 1, col, strategy)) return 1;
        if (solve_maze(grid, row, col + 1, strategy)) return 1;
        if (solve_maze(grid, row - 1, col, strategy)) return 1;
        if (solve_maze(grid, row, col - 1, strategy)) return 1;
    } else {
        if (solve_maze(grid, row - 1, col, strategy)) return 1;
        if (solve_maze(grid, row, col + 1, strategy)) return 1;
        if (solve_maze(grid, row + 1, col, strategy)) return 1;
        if (solve_maze(grid, row, col - 1, strategy)) return 1;
    }

    grid[index] = 3;
    return 0;
}

static void put_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t maze_recursion(const int64_t *input, size_t length,
                       uint8_t *output, size_t capacity) {
    if (input == NULL || length != INPUT_WORDS) return -1;
    if (input[0] < 0 || input[0] > 1) return -1;
    const int strategy = (int)input[0];

    uint8_t grid[GRID_CELLS];
    for (size_t index = 0; index < GRID_CELLS; ++index) {
        const int64_t cell = input[index + 1];
        if (cell != 0 && cell != 1) return -1;
        grid[index] = (uint8_t)cell;
    }
    for (size_t row = 0; row < GRID_ROWS; ++row) {
        for (size_t col = 0; col < GRID_COLS; ++col) {
            if ((row == 0 || row == GRID_ROWS - 1 || col == 0 || col == GRID_COLS - 1) &&
                grid[row * GRID_COLS + col] != 1) return -1;
        }
    }
    if (grid[START_INDEX] != 0 || grid[TARGET_INDEX] != 0) return -1;
    if (output == NULL || capacity < OUTPUT_BYTES) return -2;

    const int found = solve_maze(grid, 1, 1, strategy);
    uint8_t buffer[OUTPUT_BYTES];
    put_i32_le(buffer, 0, found);
    for (size_t index = 0; index < GRID_CELLS; ++index)
        put_i32_le(buffer, 4 * (index + 1), grid[index]);
    for (size_t index = 0; index < OUTPUT_BYTES; ++index) output[index] = buffer[index];
    return OUTPUT_BYTES;
}
