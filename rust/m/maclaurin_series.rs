const INVALID_RESULT: f64 = -1.0e300;
const PI: f64 = 3.14159265358979323846264338327950288;

fn factorial(n: i64) -> f64 { let mut result = 1.0; for i in 2..=n { result *= i as f64; } result }

#[no_mangle]
pub extern "C" fn maclaurin_series(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return INVALID_RESULT; }
    let mode = unsafe { *values };
    let theta_input = unsafe { *values.add(1) };
    let accuracy = unsafe { *values.add(2) };
    if (mode != 0 && mode != 1) || !(-10..=10).contains(&theta_input) || !(1..=30).contains(&accuracy) { return INVALID_RESULT; }
    let mut theta = theta_input as f64;
    let div = (theta / (2.0 * PI)).floor();
    theta = theta - 2.0 * div * PI;
    let mut sum = 0.0;
    for r in 0..accuracy {
        let exponent = if mode == 0 { 2 * r + 1 } else { 2 * r };
        let sign = if r % 2 == 0 { 1.0 } else { -1.0 };
        sum += sign * theta.powf(exponent as f64) / factorial(exponent);
    }
    sum
}
