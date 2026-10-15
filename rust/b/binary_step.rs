/// Binary step over a bounded finite binary64 domain.
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn binary_step(x: f64) -> f64 {
    if !x.is_finite() || !(-1_000_000.0..=1_000_000.0).contains(&x) {
        return INVALID_RESULT;
    }
    if x >= 0.0 { 1.0 } else { 0.0 }
}
