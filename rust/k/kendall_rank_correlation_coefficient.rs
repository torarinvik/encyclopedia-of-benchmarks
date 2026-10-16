use std::slice;

const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn kendall_rank_correlation_coefficient(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 5 || length > 257 { return INVALID_RESULT; }
    let input = unsafe { slice::from_raw_parts(values, length) };
    let count = input[0];
    if count < 2 || count > 128 || length != 1 + 2 * count as usize { return INVALID_RESULT; }
    if input[1..].iter().any(|&value| value < -1_000_000 || value > 1_000_000) { return INVALID_RESULT; }

    let n = count as usize;
    let (x_values, y_values) = (&input[1..1 + n], &input[1 + n..]);
    let mut concordant = 0_i64;
    let mut discordant = 0_i64;
    let mut ties_x = 0_i64;
    let mut ties_y = 0_i64;
    for i in 0..n {
        for j in i + 1..n {
            let (x1, x2, y1, y2) = (x_values[i], x_values[j], y_values[i], y_values[j]);
            if x1 == x2 { ties_x += 1; }
            if y1 == y2 { ties_y += 1; }
            if (x1 < x2 && y1 < y2) || (x1 > x2 && y1 > y2) { concordant += 1; }
            else if (x1 < x2 && y1 > y2) || (x1 > x2 && y1 < y2) { discordant += 1; }
        }
    }
    let pairs = (n * (n - 1) / 2) as f64;
    let denominator = ((pairs - ties_x as f64) * (pairs - ties_y as f64)).sqrt();
    if denominator == 0.0 { return INVALID_RESULT; }
    (concordant - discordant) as f64 / denominator
}
