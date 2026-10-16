/// Binary negative log-likelihood with source-ordered accumulation.
#[no_mangle]
pub extern "C" fn negative_log_likelihood(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 1 { return -1.0e300; }
    let count = unsafe { *values };
    if !(1..=64).contains(&count) || length != 1 + 2 * count as usize { return -1.0e300; }
    let mut total = 0.0;
    for i in 0..count as usize {
        let actual_scaled = unsafe { *values.add(1 + i) };
        let predicted_scaled = unsafe { *values.add(1 + count as usize + i) };
        if !(0..=1_000_000).contains(&actual_scaled) || !(1..=999_999).contains(&predicted_scaled) {
            return -1.0e300;
        }
        let actual = actual_scaled as f64 / 1_000_000.0;
        let predicted = predicted_scaled as f64 / 1_000_000.0;
        total += -actual * predicted.ln() - (1.0 - actual) * (1.0 - predicted).ln();
    }
    total / count as f64
}
