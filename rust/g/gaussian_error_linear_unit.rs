/// Pinned Python GELU approximation: x * (1 / (1 + exp(-1.702*x))).
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn gaussian_error_linear_unit(x: f64) -> f64 {
    if !x.is_finite() || x < -100.0 || x > 100.0 { return INVALID_RESULT; }
    x * (1.0 / (1.0 + (-1.702 * x).exp()))
}
