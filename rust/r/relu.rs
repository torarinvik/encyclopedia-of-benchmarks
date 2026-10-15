/// Rectified linear unit over a bounded integer-valued binary64 domain.
const INVALID_RESULT: f64 = -1.0e300;
const MAX_INPUT: f64 = 16_777_216.0;

#[no_mangle]
pub extern "C" fn relu(x: f64) -> f64 {
    if !x.is_finite() || x < -MAX_INPUT || x > MAX_INPUT || x.fract() != 0.0 {
        return INVALID_RESULT;
    }
    if x > 0.0 { x } else { 0.0 }
}
