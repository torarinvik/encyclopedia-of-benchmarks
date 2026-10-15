const MAX_OBSERVATIONS: usize = 64;
const MAX_EPOCHS: i64 = 10_000;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn linear_regression_gradient_descent(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 7 || length > 131 || length % 2 == 0 { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let count = values[0];
    let rate_microunits = values[1];
    let epochs = values[2];
    if !(2..=MAX_OBSERVATIONS as i64).contains(&count) || length != 3 + 2 * count as usize ||
        !(1..=1000).contains(&rate_microunits) || !(1..=MAX_EPOCHS).contains(&epochs) {
        return INVALID_RESULT;
    }
    for index in 0..count as usize {
        let x = values[3 + 2 * index];
        let y = values[4 + 2 * index];
        if !(-10..=10).contains(&x) || !(-100..=100).contains(&y) { return INVALID_RESULT; }
    }

    let alpha = rate_microunits as f64 / 1_000_000.0;
    let scale = alpha / count as f64;
    let mut slope = 0.0;
    let mut intercept = 0.0;
    for _ in 0..epochs {
        let mut slope_gradient = 0.0;
        let mut intercept_gradient = 0.0;
        for index in 0..count as usize {
            let x = values[3 + 2 * index] as f64;
            let y = values[4 + 2 * index] as f64;
            let error = slope * x + intercept - y;
            slope_gradient += error * x;
            intercept_gradient += error;
        }
        slope -= scale * slope_gradient;
        intercept -= scale * intercept_gradient;
    }
    slope
}
