const INVALID_RESULT: i64 = i64::MIN;

#[no_mangle]
pub extern "C" fn minimum_cost_path(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let (rv, cv) = (values[0], values[1]);
    if !(1..=16).contains(&rv) || !(1..=16).contains(&cv) { return INVALID_RESULT; }
    let (rows, cols) = (rv as usize, cv as usize);
    if length != 2 + rows * cols { return INVALID_RESULT; }
    let mut dp = [[0i64; 16]; 16];
    for r in 0..rows {
        for c in 0..cols {
            let x = values[2 + r * cols + c];
            if x < i32::MIN as i64 || x > i32::MAX as i64 { return INVALID_RESULT; }
            dp[r][c] = x;
        }
    }
    for c in 1..cols { dp[0][c] += dp[0][c - 1]; }
    for r in 1..rows { dp[r][0] += dp[r - 1][0]; }
    for r in 1..rows {
        for c in 1..cols { dp[r][c] += dp[r - 1][c].min(dp[r][c - 1]); }
    }
    dp[rows - 1][cols - 1]
}
