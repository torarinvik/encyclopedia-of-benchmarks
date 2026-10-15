/// Pinned Python Swish expression with trainable_parameter fixed to 1.
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn swish(x: f64) -> f64 {
    if !x.is_finite() || x < -100.0 || x > 100.0 { return INVALID_RESULT; }
    let scaled = 1.0 * x;
    x * (1.0 / (1.0 + (-scaled).exp()))
}
