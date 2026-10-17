const INVALID_RESULT: f64 = -1.0e300;

fn objective(x: f64) -> f64 { x * x - 3.0 }

fn secant_impl(values: &[i64]) -> f64 {
    if values.len() != 5 || values[0] != 0 ||
        !(1_000_000..=1_500_000).contains(&values[1]) ||
        !(1_600_000..=2_000_000).contains(&values[2]) || values[1] >= values[2] ||
        !(1..=100_000).contains(&values[3]) || !(0..=32).contains(&values[4]) {
        return INVALID_RESULT;
    }
    let mut x0 = values[1] as f64 / 1_000_000.0;
    let mut x1 = values[2] as f64 / 1_000_000.0;
    let tolerance = values[3] as f64 / 1_000_000_000.0;
    let max_updates = values[4] as usize;
    for update in 0..=max_updates {
        let f1 = objective(x1);
        if f1.abs() <= tolerance { return x1; }
        if update == max_updates { break; }
        let f0 = objective(x0);
        let denominator = f1 - f0;
        if denominator == 0.0 { return INVALID_RESULT; }
        let x2 = x1 - f1 * (x1 - x0) / denominator;
        if !x2.is_finite() { return INVALID_RESULT; }
        x0 = x1;
        x1 = x2;
    }
    INVALID_RESULT
}

#[no_mangle]
pub unsafe extern "C" fn secant(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 5 { return INVALID_RESULT; }
    secant_impl(std::slice::from_raw_parts(values, length))
}
