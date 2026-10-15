fn flood(cells: &[i64], visited: &mut [bool; 256], rows: usize, cols: usize, row: isize, col: isize) {
    if row < 0 || col < 0 || row >= rows as isize || col >= cols as isize { return; }
    let index = row as usize * cols + col as usize;
    if cells[index] != 1 || visited[index] { return; }
    visited[index] = true;
    flood(cells, visited, rows, cols, row + 1, col);
    flood(cells, visited, rows, cols, row - 1, col);
    flood(cells, visited, rows, cols, row, col + 1);
    flood(cells, visited, rows, cols, row, col - 1);
}

#[no_mangle]
pub extern "C" fn number_of_islands(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if !(1..=16).contains(&values[0]) || !(1..=16).contains(&values[1]) { return -1; }
    let rows = values[0] as usize;
    let cols = values[1] as usize;
    if length != 2 + rows * cols || values[2..].iter().any(|&cell| cell != 0 && cell != 1) { return -1; }
    let cells = &values[2..];
    let mut visited = [false; 256];
    let mut count = 0;
    for row in 0..rows {
        for col in 0..cols {
            let index = row * cols + col;
            if cells[index] == 1 && !visited[index] {
                count += 1;
                flood(cells, &mut visited, rows, cols, row as isize, col as isize);
            }
        }
    }
    count
}
