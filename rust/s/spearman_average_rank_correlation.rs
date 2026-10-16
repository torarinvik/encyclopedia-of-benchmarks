use std::slice;

const INVALID_RESULT: f64 = -1.0e300;

fn average_rank(samples: &[i64], index: usize) -> f64 {
    let value = samples[index];
    let mut less = 0_i64;
    let mut equal = 0_i64;
    for &other in samples {
        if other < value { less += 1; }
        if other == value { equal += 1; }
    }
    less as f64 + (equal as f64 + 1.0) / 2.0
}

#[no_mangle]
pub extern "C" fn spearman_average_rank_correlation(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 5 || length > 257 { return INVALID_RESULT; }
    let input = unsafe { slice::from_raw_parts(values, length) };
    let count = input[0];
    if count < 2 || count > 128 || length != 1 + 2 * count as usize { return INVALID_RESULT; }
    let n = count as usize;
    if input[1..].iter().any(|&value| value < -1_000_000 || value > 1_000_000) { return INVALID_RESULT; }
    let x_values = &input[1..1 + n];
    let y_values = &input[1 + n..];
    let mean_rank = (n as f64 + 1.0) / 2.0;
    let mut covariance = 0.0;
    let mut variance_x = 0.0;
    let mut variance_y = 0.0;
    for i in 0..n {
        let dx = average_rank(x_values, i) - mean_rank;
        let dy = average_rank(y_values, i) - mean_rank;
        covariance += dx * dy;
        variance_x += dx * dx;
        variance_y += dy * dy;
    }
    if variance_x == 0.0 || variance_y == 0.0 { return INVALID_RESULT; }
    covariance / (variance_x * variance_y).sqrt()
}
