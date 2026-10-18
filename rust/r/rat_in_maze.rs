const MAX_DIMENSION: usize = 8;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 71;
const MAX_OUTPUT_BYTES: usize = MAX_CELLS * 8;
const PYTHON_VARIANT: i64 = 0;
const RUST_VARIANT: i64 = 1;

struct Maze {
    variant: usize,
    rows: usize,
    cols: usize,
    start_row: usize,
    start_col: usize,
    destination_row: usize,
    destination_col: usize,
    cells: [i64; MAX_CELLS],
}

fn parse_maze(values: &[i64]) -> Option<Maze> {
    if values.is_empty() || values.len() > MAX_PARSEABLE_INPUT_LENGTH { return None; }
    let mut maze = Maze {
        variant: 0, rows: 0, cols: 0, start_row: 0, start_col: 0,
        destination_row: 0, destination_col: 0, cells: [0; MAX_CELLS],
    };
    if values[0] == PYTHON_VARIANT {
        if values.len() < 7 || values[1] < 1 || values[1] > MAX_DIMENSION as i64 { return None; }
        let size = values[1] as usize;
        if values.len() != 6 + size * size { return None; }
        for coordinate in &values[2..6] {
            if *coordinate < 0 || *coordinate >= size as i64 { return None; }
        }
        maze.variant = PYTHON_VARIANT as usize;
        maze.rows = size;
        maze.cols = size;
        maze.start_row = values[2] as usize;
        maze.start_col = values[3] as usize;
        maze.destination_row = values[4] as usize;
        maze.destination_col = values[5] as usize;
        for index in 0..size * size {
            let cell = values[6 + index];
            if cell != 0 && cell != 1 { return None; }
            maze.cells[index] = cell;
        }
    } else if values[0] == RUST_VARIANT {
        if values.len() < 6 || values[1] < 1 || values[1] > MAX_DIMENSION as i64 ||
            values[2] < 1 || values[2] > MAX_DIMENSION as i64 { return None; }
        let rows = values[1] as usize;
        let cols = values[2] as usize;
        if values.len() != 5 + rows * cols || values[3] < 0 || values[3] >= rows as i64 ||
            values[4] < 0 || values[4] >= cols as i64 { return None; }
        maze.variant = RUST_VARIANT as usize;
        maze.rows = rows;
        maze.cols = cols;
        maze.start_row = values[3] as usize;
        maze.start_col = values[4] as usize;
        maze.destination_row = rows - 1;
        maze.destination_col = cols - 1;
        for index in 0..rows * cols {
            let cell = values[5 + index];
            if cell != 0 && cell != 1 { return None; }
            maze.cells[index] = cell;
        }
    } else { return None; }
    Some(maze)
}

fn direction(variant: usize, movement: usize) -> (isize, isize) {
    if variant == 0 {
        match movement { 0 => (1, 0), 1 => (0, 1), 2 => (-1, 0), _ => (0, -1) }
    } else {
        match movement { 0 => (0, 1), 1 => (1, 0), 2 => (0, -1), _ => (-1, 0) }
    }
}

fn search_path(maze: &Maze, row: isize, col: isize, path: &mut [bool; MAX_CELLS]) -> bool {
    if maze.variant == RUST_VARIANT as usize && row == maze.destination_row as isize &&
        col == maze.destination_col as isize {
        path[row as usize * maze.cols + col as usize] = true;
        return true;
    }
    if row < 0 || col < 0 || row >= maze.rows as isize || col >= maze.cols as isize { return false; }
    let index = row as usize * maze.cols + col as usize;
    let open_value = if maze.variant == PYTHON_VARIANT as usize { 0 } else { 1 };
    if maze.cells[index] != open_value || path[index] { return false; }
    path[index] = true;
    if maze.variant == PYTHON_VARIANT as usize && row == maze.destination_row as isize &&
        col == maze.destination_col as isize { return true; }
    for movement in 0..4 {
        let (delta_row, delta_col) = direction(maze.variant, movement);
        if search_path(maze, row + delta_row, col + delta_col, path) { return true; }
    }
    path[index] = false;
    false
}

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn rat_in_maze(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let Some(maze) = parse_maze(values) else { return -1; };
    let mut path = [false; MAX_CELLS];
    if !search_path(&maze, maze.start_row as isize, maze.start_col as isize, &mut path) { return -3; }

    let cells = maze.rows * maze.cols;
    let output_bytes = cells * 8;
    if output_bytes > MAX_OUTPUT_BYTES { return -1; }
    if output.is_null() || output_capacity < output_bytes { return -2; }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);
    for index in 0..cells {
        let value = if maze.variant == PYTHON_VARIANT as usize {
            if path[index] { 0 } else { 1 }
        } else if path[index] { 1 } else { 0 };
        write_i64_le(output_slice, index * 8, value);
    }
    output_bytes as i64
}
