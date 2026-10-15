const MAX_OBSERVATIONS: usize = 128;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn linear_regression_ols(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 5 || length > 257 || length % 2 == 0 { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let count = values[0];
    if !(2..=MAX_OBSERVATIONS as i64).contains(&count) || length != 1 + 2 * count as usize {
        return INVALID_RESULT;
    }

    let mut sum_x = 0.0;
    let mut sum_y = 0.0;
    for index in 0..count as usize {
        let x = values[1 + 2 * index];
        let y = values[2 + 2 * index];
        if !(-1_000_000..=1_000_000).contains(&x) || !(-1_000_000..=1_000_000).contains(&y) {
            return INVALID_RESULT;
        }
        sum_x += x as f64;
        sum_y += y as f64;
    }
    let mean_x = sum_x / count as f64;
    let mean_y = sum_y / count as f64;
    let mut covariance = 0.0;
    let mut variance_x = 0.0;
    let mut variance_y = 0.0;
    for index in 0..count as usize {
        let dx = values[1 + 2 * index] as f64 - mean_x;
        let dy = values[2 + 2 * index] as f64 - mean_y;
        covariance += dx * dy;
        variance_x += dx * dx;
        variance_y += dy * dy;
    }
    if variance_x <= 1e-12 || variance_y <= 1e-12 { return INVALID_RESULT; }
    covariance / variance_x
}
