/// Build a padded two-dimensional prefix table and answer one inclusive rectangle.
const INVALID_RESULT: i64 = i64::MIN;
const MAX_DIMENSION: usize = 16;

#[no_mangle]
pub extern "C" fn prefix_sum2_d(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 7 { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (raw_rows, raw_cols) = (values[0], values[1]);
    if raw_rows < 1 || raw_rows > MAX_DIMENSION as i64 || raw_cols < 1 || raw_cols > MAX_DIMENSION as i64 { return INVALID_RESULT; }
    let (rows, cols) = (raw_rows as usize, raw_cols as usize);
    if length != 2 + rows * cols + 4 { return INVALID_RESULT; }
    let query = 2 + rows * cols;
    let (row1v, col1v, row2v, col2v) = (values[query], values[query + 1], values[query + 2], values[query + 3]);
    if row1v < 0 || col1v < 0 || row2v < row1v || col2v < col1v ||
        row2v as u64 >= rows as u64 || col2v as u64 >= cols as u64 { return INVALID_RESULT; }
    let mut prefix = [[0i64; MAX_DIMENSION + 1]; MAX_DIMENSION + 1];
    for i in 0..rows {
        for j in 0..cols {
            let value = values[2 + i * cols + j];
            if !(-1000..=1000).contains(&value) { return INVALID_RESULT; }
            prefix[i + 1][j + 1] = value + prefix[i][j + 1] + prefix[i + 1][j] - prefix[i][j];
        }
    }
    let (row1, col1, row2, col2) = (row1v as usize, col1v as usize, row2v as usize, col2v as usize);
    prefix[row2 + 1][col2 + 1] - prefix[row1][col2 + 1] - prefix[row2 + 1][col1] + prefix[row1][col1]
}
