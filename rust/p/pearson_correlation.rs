use std::slice;

const MAX_OBSERVATIONS: usize = 128;
const MAX_ABS_VALUE: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn pearson_correlation(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 5 || length > 257 { return INVALID_RESULT; }
    let input = unsafe { slice::from_raw_parts(values, length) };
    let count = input[0];
    if count < 2 || count > MAX_OBSERVATIONS as i64 || length != 1 + 2 * count as usize {
        return INVALID_RESULT;
    }

    let n = count as usize;
    let (x_values, y_values) = (&input[1..1 + n], &input[1 + n..]);
    if x_values.iter().chain(y_values).any(|&value| value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE) {
        return INVALID_RESULT;
    }
    let sum_x: f64 = x_values.iter().map(|&value| value as f64).sum();
    let sum_y: f64 = y_values.iter().map(|&value| value as f64).sum();
    let mean_x = sum_x / n as f64;
    let mean_y = sum_y / n as f64;
    let mut covariance = 0.0;
    let mut variance_x = 0.0;
    let mut variance_y = 0.0;
    for (&x, &y) in x_values.iter().zip(y_values) {
        let dx = x as f64 - mean_x;
        let dy = y as f64 - mean_y;
        covariance += dx * dy;
        variance_x += dx * dx;
        variance_y += dy * dy;
    }
    if variance_x == 0.0 || variance_y == 0.0 { return INVALID_RESULT; }
    covariance / (variance_x * variance_y).sqrt()
}
