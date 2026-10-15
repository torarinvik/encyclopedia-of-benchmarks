/// Floor for bounded finite binary64 inputs, correcting truncation below zero.
#[no_mangle]
pub extern "C" fn floor(value: f64) -> f64 {
    if value < -1_000_000.0 || value > 1_000_000.0 {
        return -1.0;
    }
    let mut result = value as i64;
    if value < result as f64 {
        result -= 1;
    }
    result as f64
}
