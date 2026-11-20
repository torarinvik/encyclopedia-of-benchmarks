const MAX_CELLS: usize = 64;

#[no_mangle]
pub unsafe extern "C" fn recursive_backtracker_maze_generation(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(4..=68).contains(&length) { return -1; }
    let data = unsafe { std::slice::from_raw_parts(input, length) };
    let (rows_word, cols_word, start_word, draw_count) = (data[0], data[1], data[2], data[3]);
    if !(1..=64).contains(&rows_word) || !(1..=64).contains(&cols_word) { return -1; }
    let (rows, cols) = (rows_word as usize, cols_word as usize);
    let cells = rows * cols;
    if cells > MAX_CELLS || start_word < 0 || start_word as usize >= cells ||
        draw_count != (cells - 1) as i64 || length != 4 + cells - 1 { return -1; }
    if data[4..].iter().any(|&draw| !(0..=3).contains(&draw)) { return -1; }

    let mut visited = [false; MAX_CELLS];
    let mut walls = [15u8; MAX_CELLS];
    let mut stack = [0usize; MAX_CELLS];
    let (mut depth, mut cursor) = (1usize, 0usize);
    stack[0] = start_word as usize;
    visited[stack[0]] = true;
    while depth > 0 {
        let cell = stack[depth - 1];
        let (row, col) = (cell / cols, cell % cols);
        let mut next_cells = [0usize; 4];
        let mut directions = [0usize; 4];
        let mut count = 0usize;
        if row > 0 && !visited[cell - cols] { next_cells[count] = cell - cols; directions[count] = 0; count += 1; }
        if col + 1 < cols && !visited[cell + 1] { next_cells[count] = cell + 1; directions[count] = 1; count += 1; }
        if row + 1 < rows && !visited[cell + cols] { next_cells[count] = cell + cols; directions[count] = 2; count += 1; }
        if col > 0 && !visited[cell - 1] { next_cells[count] = cell - 1; directions[count] = 3; count += 1; }
        if count == 0 { depth -= 1; continue; }
        if cursor >= cells - 1 { return -1; }
        let choice = data[4 + cursor] as usize;
        cursor += 1;
        if choice >= count { return -1; }
        let (next, direction) = (next_cells[choice], directions[choice]);
        visited[next] = true;
        walls[cell] &= !(1u8 << direction);
        walls[next] &= !(1u8 << ((direction + 2) & 3));
        stack[depth] = next;
        depth += 1;
    }
    if cursor != cells - 1 || visited[..cells].iter().any(|&cell| !cell) { return -1; }
    if output.is_null() || capacity < cells { return -2; }
    let destination = unsafe { std::slice::from_raw_parts_mut(output, cells) };
    destination.copy_from_slice(&walls[..cells]);
    cells as i64
}
