/// Count four-neighbor vertex-simple grid paths by recursive DFS.
fn count_from(values: &[i64], rows: usize, cols: usize, row: isize, col: isize, visited: u32) -> i64 {
    if row < 0 || col < 0 || row >= rows as isize || col >= cols as isize { return 0; }
    let index = row as usize * cols + col as usize;
    let mask = 1u32 << index;
    if values[2 + index] == 1 || (visited & mask) != 0 { return 0; }
    if row as usize == rows - 1 && col as usize == cols - 1 { return 1; }
    let seen = visited | mask;
    count_from(values, rows, cols, row + 1, col, seen)
        + count_from(values, rows, cols, row - 1, col, seen)
        + count_from(values, rows, cols, row, col + 1, seen)
        + count_from(values, rows, cols, row, col - 1, seen)
}

#[no_mangle]
pub extern "C" fn count_paths(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if !(1..=5).contains(&values[0]) || !(1..=5).contains(&values[1]) { return -1; }
    let rows = values[0] as usize;
    let cols = values[1] as usize;
    if rows * cols > 25 || length != 2 + rows * cols { return -1; }
    if values[2..].iter().any(|&cell| cell != 0 && cell != 1) { return -1; }
    count_from(values, rows, cols, 0, 0, 0)
}
