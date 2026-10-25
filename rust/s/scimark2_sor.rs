const MAX_ROWS: usize = 8;
const MAX_COLS: usize = 8;
const MAX_INPUT: usize = 3 + MAX_ROWS * MAX_COLS;

#[no_mangle]
pub unsafe extern "C" fn scimark2_sor(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let row_value = *input;
    let col_value = *input.add(1);
    let iteration_value = *input.add(2);
    if !(2..=MAX_ROWS as i64).contains(&row_value) || !(2..=MAX_COLS as i64).contains(&col_value) ||
        !(0..=8).contains(&iteration_value) { return -1; }
    let rows = row_value as usize;
    let cols = col_value as usize;
    let iterations = iteration_value as usize;
    if length != 3 + rows * cols { return -1; }
    let mut grid = [0i64; MAX_ROWS * MAX_COLS];
    for i in 0..rows * cols {
        let value = *input.add(3 + i);
        if !(-1000..=1000).contains(&value) { return -1; }
        grid[i] = value;
    }
    for _ in 0..iterations {
        for row in 1..rows - 1 {
            for col in 1..cols - 1 {
                let index = row * cols + col;
                let neighbors = grid[index - cols] + grid[index + cols] + grid[index - 1] + grid[index + 1];
                let numerator = 1250 * neighbors - 1000 * grid[index];
                grid[index] = numerator / 4000;
            }
        }
    }
    (0..rows * cols).map(|i| (i as i64 + 1) * grid[i]).sum()
}
