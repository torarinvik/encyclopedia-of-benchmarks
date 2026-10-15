const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn softsign(x: f64) -> f64 {
    if !x.is_finite() || x < -1.0e100 || x > 1.0e100 {
        return INVALID_RESULT;
    }
    x / (1.0 + x.abs())
}
