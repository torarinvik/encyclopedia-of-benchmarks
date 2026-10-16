/// Conventional exponential linear unit from the pinned MATLAB formula.
const INVALID_RESULT: f64 = -1.0e300;
const ALPHA_MAX: f64 = 1_000_000.0;

#[no_mangle]
pub extern "C" fn elu(x: f64, alpha: f64) -> f64 {
    if !x.is_finite() || !alpha.is_finite() || x < -100.0 || x > 100.0
        || alpha < -ALPHA_MAX || alpha > ALPHA_MAX {
        return INVALID_RESULT;
    }
    if x < 0.0 { alpha * (x.exp() - 1.0) } else { x }
}
