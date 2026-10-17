const MAX_N: usize = 8;
const MAX_INPUT_WORDS: usize = 1 + MAX_N * MAX_N;
const MAX_OUTPUT_WORDS: usize = 1 + MAX_N * MAX_N;

fn search_path(maze: &[i32], path: &mut [i32; MAX_N * MAX_N], n: usize, row: usize, col: usize) -> bool {
    let index = row * n + col;
    path[index] = 1;
    if row == n - 1 && col == n - 1 { return true; }
    if col + 1 < n && maze[index + 1] == 1 && search_path(maze, path, n, row, col + 1) { return true; }
    if row + 1 < n && maze[index + n] == 1 && search_path(maze, path, n, row + 1, col) { return true; }
    path[index] = 0;
    false
}

#[no_mangle]
pub unsafe extern "C" fn rat_maze(input: *const i32, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_WORDS { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    if !(1..=MAX_N as i32).contains(&n_raw) { return -1; }
    let n = n_raw as usize;
    let cells = n * n;
    if length != 1 + cells || values[1] != 1 || values[1..].iter().any(|&value| !(0..=1).contains(&value)) { return -1; }
    let mut path = [0i32; MAX_N * MAX_N];
    let found = search_path(&values[1..], &mut path, n, 0, 0);
    let word_count = if found { 1 + cells } else { 1 };
    let bytes = word_count * 4;
    if output.is_null() || capacity < bytes { return -2; }
    let mut buffer = [0u8; MAX_OUTPUT_WORDS * 4];
    buffer[..4].copy_from_slice(&(found as i32).to_le_bytes());
    if found {
        for i in 0..cells { buffer[(i + 1) * 4..(i + 2) * 4].copy_from_slice(&path[i].to_le_bytes()); }
    }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, bytes);
    bytes as i64
}
