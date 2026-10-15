const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn softplus(x: f64) -> f64 {
    if !x.is_finite() || x < -100.0 || x > 100.0 {
        return INVALID_RESULT;
    }
    (1.0 + x.exp()).ln()
}
