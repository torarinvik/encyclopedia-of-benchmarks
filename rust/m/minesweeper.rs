const MAX_DIM: usize = 32;
const MAX_CELLS: usize = MAX_DIM * MAX_DIM;
const MAX_OUTPUT: usize = 8 + 8 * MAX_CELLS;

#[no_mangle]
pub unsafe extern "C" fn minesweeper(input: *const i64, length: usize,
                                      output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 2 + MAX_CELLS { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (rows_value, cols_value) = (values[0], values[1]);
    if !(1..=MAX_DIM as i64).contains(&rows_value) || !(1..=MAX_DIM as i64).contains(&cols_value) { return -1; }
    let (rows, cols) = (rows_value as usize, cols_value as usize);
    let count = rows * cols;
    if length != 2 + count || values[2..].iter().any(|&cell| cell != 0 && cell != 1) { return -1; }
    let cells = &values[2..];
    let mut neighbors = [0_i64; MAX_CELLS];
    for row in 0..rows { for col in 0..cols {
        let mut mines = 0_i64;
        for dr in -1_i32..=1 { for dc in -1_i32..=1 {
            if dr == 0 && dc == 0 { continue; }
            let nr = row as i32 + dr; let nc = col as i32 + dc;
            if nr >= 0 && nr < rows as i32 && nc >= 0 && nc < cols as i32 && cells[nr as usize * cols + nc as usize] == 1 { mines += 1; }
        }}
        neighbors[row * cols + col] = mines;
    }}
    let needed = 8 + 8 * count;
    if output.is_null() || capacity < needed { return -2; }
    let mut payload = [0_u8; MAX_OUTPUT];
    payload[..8].copy_from_slice(&(count as i64).to_le_bytes());
    for i in 0..count { payload[8 + 8 * i..16 + 8 * i].copy_from_slice(&neighbors[i].to_le_bytes()); }
    std::ptr::copy_nonoverlapping(payload.as_ptr(), output, needed);
    needed as i64
}
