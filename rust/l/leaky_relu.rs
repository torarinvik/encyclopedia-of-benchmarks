/// Leaky ReLU for one vector element and a caller-supplied slope.
const INVALID_RESULT: f64 = -1.0e300;
const MAX_INPUT: f64 = 1_000_000.0;

#[no_mangle]
pub extern "C" fn leaky_relu(x: f64, alpha: f64) -> f64 {
    if !x.is_finite() || !alpha.is_finite() || x < -MAX_INPUT || x > MAX_INPUT
        || alpha < -MAX_INPUT || alpha > MAX_INPUT {
        return INVALID_RESULT;
    }
    if x < 0.0 { x * alpha } else { x }
}
