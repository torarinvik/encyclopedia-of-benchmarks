const GRID_ROWS: usize = 8;
const GRID_COLS: usize = 7;
const GRID_CELLS: usize = GRID_ROWS * GRID_COLS;
const INPUT_WORDS: usize = 1 + GRID_CELLS;
const OUTPUT_BYTES: usize = 4 * INPUT_WORDS;
const START_INDEX: usize = 1 * GRID_COLS + 1;
const TARGET_INDEX: usize = 6 * GRID_COLS + 5;

fn solve_maze(grid: &mut [u8; GRID_CELLS], row: isize, col: isize, strategy: i64) -> bool {
    if grid[TARGET_INDEX] == 2 {
        return true;
    }
    let index = (row as usize) * GRID_COLS + col as usize;
    if grid[index] != 0 {
        return false;
    }
    grid[index] = 2;

    if strategy == 0 {
        if solve_maze(grid, row + 1, col, strategy) { return true; }
        if solve_maze(grid, row, col + 1, strategy) { return true; }
        if solve_maze(grid, row - 1, col, strategy) { return true; }
        if solve_maze(grid, row, col - 1, strategy) { return true; }
    } else {
        if solve_maze(grid, row - 1, col, strategy) { return true; }
        if solve_maze(grid, row, col + 1, strategy) { return true; }
        if solve_maze(grid, row + 1, col, strategy) { return true; }
        if solve_maze(grid, row, col - 1, strategy) { return true; }
    }

    grid[index] = 3;
    false
}

fn put_i32_le(output: &mut [u8], offset: usize, value: i32) {
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn maze_recursion(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != INPUT_WORDS {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=1).contains(&values[0]) {
        return -1;
    }
    let strategy = values[0];

    let mut grid = [0u8; GRID_CELLS];
    for index in 0..GRID_CELLS {
        let cell = values[index + 1];
        if cell != 0 && cell != 1 {
            return -1;
        }
        grid[index] = cell as u8;
    }
    for row in 0..GRID_ROWS {
        for col in 0..GRID_COLS {
            if (row == 0 || row == GRID_ROWS - 1 || col == 0 || col == GRID_COLS - 1)
                && grid[row * GRID_COLS + col] != 1
            {
                return -1;
            }
        }
    }
    if grid[START_INDEX] != 0 || grid[TARGET_INDEX] != 0 {
        return -1;
    }
    if output.is_null() || capacity < OUTPUT_BYTES {
        return -2;
    }

    let found = solve_maze(&mut grid, 1, 1, strategy);
    let mut buffer = [0u8; OUTPUT_BYTES];
    put_i32_le(&mut buffer, 0, if found { 1 } else { 0 });
    for index in 0..GRID_CELLS {
        put_i32_le(&mut buffer, 4 * (index + 1), grid[index] as i32);
    }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, OUTPUT_BYTES);
    OUTPUT_BYTES as i64
}
