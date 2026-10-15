/// Mish activation for one element of the source vector.
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn mish(x: f64) -> f64 {
    if !x.is_finite() || x < -20.0 || x > 20.0 { return INVALID_RESULT; }
    let softplus = (1.0 + x.exp()).ln();
    x * softplus.tanh()
}
