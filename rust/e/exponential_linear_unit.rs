/// Preserve the pinned Rust ELU implementation for one vector element.
const INVALID_RESULT: f64 = -1.0e300;
const ALPHA_MAX: f64 = 1_000_000.0;

#[no_mangle]
pub extern "C" fn exponential_linear_unit(x: f64, alpha: f64) -> f64 {
    if !x.is_finite() || !alpha.is_finite() || x < -100.0 || x > 100.0
        || alpha < -ALPHA_MAX || alpha > ALPHA_MAX {
        return INVALID_RESULT;
    }
    if x < 0.0 {
        x * (alpha * (std::f64::consts::E.powf(x) - 1.0))
    } else {
        x
    }
}
