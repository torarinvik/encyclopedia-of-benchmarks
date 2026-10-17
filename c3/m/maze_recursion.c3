module maze_recursion;

const usz GRID_ROWS = 8;
const usz GRID_COLS = 7;
const usz GRID_CELLS = 56;
const usz INPUT_WORDS = 57;
const usz OUTPUT_BYTES = 228;
const usz START_INDEX = 8;
const usz TARGET_INDEX = 47;

fn bool solve_maze(uchar* grid, int row, int col, int strategy) {
    if (grid[TARGET_INDEX] == 2) return true;
    usz index = (usz)(row * 7 + col);
    if (grid[index] != 0) return false;
    grid[index] = 2;

    if (strategy == 0) {
        if (solve_maze(grid, row + 1, col, strategy)) return true;
        if (solve_maze(grid, row, col + 1, strategy)) return true;
        if (solve_maze(grid, row - 1, col, strategy)) return true;
        if (solve_maze(grid, row, col - 1, strategy)) return true;
    } else {
        if (solve_maze(grid, row - 1, col, strategy)) return true;
        if (solve_maze(grid, row, col + 1, strategy)) return true;
        if (solve_maze(grid, row + 1, col, strategy)) return true;
        if (solve_maze(grid, row, col - 1, strategy)) return true;
    }

    grid[index] = 3;
    return false;
}

fn void put_i32_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long maze_recursion(long* input, usz length, char* output, usz capacity)
        @export("maze_recursion") {
    if (input == null || length != INPUT_WORDS) return -1;
    if (input[0] < 0 || input[0] > 1) return -1;
    int strategy = (int)input[0];

    uchar[GRID_CELLS] grid;
    for (usz index = 0; index < GRID_CELLS; index += 1) {
        long cell = input[index + 1];
        if (cell != 0 && cell != 1) return -1;
        grid[index] = (uchar)cell;
    }
    for (usz row = 0; row < GRID_ROWS; row += 1) {
        for (usz col = 0; col < GRID_COLS; col += 1) {
            if ((row == 0 || row == GRID_ROWS - 1 || col == 0 || col == GRID_COLS - 1) &&
                grid[row * GRID_COLS + col] != 1) return -1;
        }
    }
    if (grid[START_INDEX] != 0 || grid[TARGET_INDEX] != 0) return -1;
    if (output == null || capacity < OUTPUT_BYTES) return -2;

    bool found = solve_maze(&grid[0], 1, 1, strategy);
    char[OUTPUT_BYTES] buffer;
    put_i32_le(&buffer[0], 0, found ? 1 : 0);
    for (usz index = 0; index < GRID_CELLS; index += 1)
        put_i32_le(&buffer[0], 4 * (index + 1), (long)grid[index]);
    for (usz index = 0; index < OUTPUT_BYTES; index += 1) output[index] = buffer[index];
    return (long)OUTPUT_BYTES;
}
