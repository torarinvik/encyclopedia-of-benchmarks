/// Hyperbolic tangent using the pinned source's f32 logistic identity.
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn tanh(x: f64) -> f64 {
    if !x.is_finite() || !(-10.0..=10.0).contains(&x) {
        return INVALID_RESULT;
    }
    let value = x as f32;
    (2.0f32 / (1.0f32 + std::f32::consts::E.powf(-2.0f32 * value)) - 1.0f32) as f64
}
