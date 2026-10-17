const GRID_ROWS: usize = 8;
const GRID_COLS: usize = 7;
const GRID_CELLS: usize = GRID_ROWS * GRID_COLS;
const INPUT_WORDS: usize = 1 + GRID_CELLS;
const OUTPUT_BYTES: usize = 4 * INPUT_WORDS;
const START_INDEX: usize = 1 * GRID_COLS + 1;
const TARGET_INDEX: usize = 6 * GRID_COLS + 5;

fn solveMaze(grid: *[GRID_CELLS]u8, row: i32, col: i32, strategy: i64) bool {
    if (grid.*[TARGET_INDEX] == 2) return true;
    const index: usize = @intCast(row * @as(i32, @intCast(GRID_COLS)) + col);
    if (grid.*[index] != 0) return false;
    grid.*[index] = 2;

    if (strategy == 0) {
        if (solveMaze(grid, row + 1, col, strategy)) return true;
        if (solveMaze(grid, row, col + 1, strategy)) return true;
        if (solveMaze(grid, row - 1, col, strategy)) return true;
        if (solveMaze(grid, row, col - 1, strategy)) return true;
    } else {
        if (solveMaze(grid, row - 1, col, strategy)) return true;
        if (solveMaze(grid, row, col + 1, strategy)) return true;
        if (solveMaze(grid, row + 1, col, strategy)) return true;
        if (solveMaze(grid, row, col - 1, strategy)) return true;
    }

    grid.*[index] = 3;
    return false;
}

fn putI32Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn maze_recursion(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length != INPUT_WORDS) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > 1) return -1;
    const strategy = values[0];

    var grid: [GRID_CELLS]u8 = @splat(0);
    for (0..GRID_CELLS) |index| {
        const cell = values[index + 1];
        if (cell != 0 and cell != 1) return -1;
        grid[index] = @intCast(cell);
    }
    for (0..GRID_ROWS) |row| {
        for (0..GRID_COLS) |col| {
            if ((row == 0 or row == GRID_ROWS - 1 or col == 0 or col == GRID_COLS - 1) and
                grid[row * GRID_COLS + col] != 1) return -1;
        }
    }
    if (grid[START_INDEX] != 0 or grid[TARGET_INDEX] != 0) return -1;
    if (output == null or capacity < OUTPUT_BYTES) return -2;

    const found = solveMaze(&grid, 1, 1, strategy);
    var buffer: [OUTPUT_BYTES]u8 = @splat(0);
    putI32Le(&buffer[0], 0, if (found) 1 else 0);
    for (0..GRID_CELLS) |index| putI32Le(&buffer[0], 4 * (index + 1), grid[index]);
    const result = output.?;
    for (0..OUTPUT_BYTES) |index| result[index] = buffer[index];
    return @intCast(OUTPUT_BYTES);
}
