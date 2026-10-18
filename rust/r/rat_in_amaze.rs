const MAX_DIMENSION: usize = 4;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const MAX_PATHS: usize = 184;
const MAX_PATH_LENGTH: usize = MAX_CELLS - 1;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 19;
const MAX_OUTPUT_WORDS: usize = 2097;
const MAX_OUTPUT_BYTES: usize = MAX_OUTPUT_WORDS * 8;
const JAVA_VARIANT: i64 = 0;
const JAVASCRIPT_VARIANT: i64 = 1;

struct Maze {
    variant: usize,
    size: usize,
    cells: [i64; MAX_CELLS],
}

struct Paths {
    directions: [[u8; MAX_PATH_LENGTH]; MAX_PATHS],
    lengths: [usize; MAX_PATHS],
    count: usize,
}

fn parse_maze(values: &[i64]) -> Option<Maze> {
    if values.is_empty() || values.len() > MAX_PARSEABLE_INPUT_LENGTH { return None; }
    if values.len() < 2 || (values[0] != JAVA_VARIANT && values[0] != JAVASCRIPT_VARIANT) { return None; }
    if values[1] < 1 || values[1] > MAX_DIMENSION as i64 { return None; }
    let size = values[1] as usize;
    let cell_count = size * size;
    if values.len() != 2 + cell_count { return None; }

    let mut maze = Maze { variant: values[0] as usize, size, cells: [0; MAX_CELLS] };
    for index in 0..cell_count {
        let cell = values[2 + index];
        if cell != 0 && cell != 1 { return None; }
        maze.cells[index] = cell;
    }
    Some(maze)
}

fn movement(variant: usize, index: usize) -> (isize, isize, u8) {
    if variant == 0 {
        match index {
            0 => (1, 0, 0),
            1 => (0, -1, 1),
            2 => (0, 1, 2),
            _ => (-1, 0, 3),
        }
    } else {
        match index {
            0 => (0, 1, 2),
            1 => (1, 0, 0),
            2 => (-1, 0, 3),
            _ => (0, -1, 1),
        }
    }
}

fn collect_paths(
    maze: &Maze,
    row: isize,
    col: isize,
    visited: &mut [bool; MAX_CELLS],
    current: &mut [u8; MAX_PATH_LENGTH],
    path_length: usize,
    paths: &mut Paths,
) -> bool {
    if row == maze.size as isize - 1 && col == maze.size as isize - 1 {
        let slot = paths.count;
        paths.count += 1;
        paths.lengths[slot] = path_length;
        paths.directions[slot][..path_length].copy_from_slice(&current[..path_length]);
        return maze.variant == JAVASCRIPT_VARIANT as usize;
    }

    let index = row as usize * maze.size + col as usize;
    visited[index] = true;
    for move_index in 0..4 {
        let (delta_row, delta_col, code) = movement(maze.variant, move_index);
        let next_row = row + delta_row;
        let next_col = col + delta_col;
        if next_row < 0 || next_col < 0 || next_row >= maze.size as isize ||
            next_col >= maze.size as isize { continue; }
        let next_index = next_row as usize * maze.size + next_col as usize;
        if maze.cells[next_index] != 1 || visited[next_index] { continue; }
        current[path_length] = code;
        if collect_paths(maze, next_row, next_col, visited, current, path_length + 1, paths) {
            visited[index] = false;
            return true;
        }
    }
    visited[index] = false;
    false
}

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn rat_in_amaze(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let Some(maze) = parse_maze(values) else { return -1; };

    let mut paths = Paths {
        directions: [[0; MAX_PATH_LENGTH]; MAX_PATHS],
        lengths: [0; MAX_PATHS],
        count: 0,
    };
    if maze.cells[0] == 1 && maze.cells[maze.size * maze.size - 1] == 1 {
        let mut visited = [false; MAX_CELLS];
        let mut current = [0; MAX_PATH_LENGTH];
        collect_paths(&maze, 0, 0, &mut visited, &mut current, 0, &mut paths);
    }
    if paths.count == 0 { return -3; }

    let output_words = 1 + (0..paths.count).map(|path| 1 + paths.lengths[path]).sum::<usize>();
    let output_bytes = output_words * 8;
    if output_bytes > MAX_OUTPUT_BYTES { return -1; }
    if output.is_null() || output_capacity < output_bytes { return -2; }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);

    let mut offset = 0;
    write_i64_le(output_slice, offset, paths.count as i64);
    offset += 8;
    for path in 0..paths.count {
        write_i64_le(output_slice, offset, paths.lengths[path] as i64);
        offset += 8;
        for movement in 0..paths.lengths[path] {
            write_i64_le(output_slice, offset, paths.directions[path][movement] as i64);
            offset += 8;
        }
    }
    output_bytes as i64
}
