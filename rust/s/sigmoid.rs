const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn sigmoid(x: f64) -> f64 {
    if !x.is_finite() || x < -20.0 || x > 20.0 {
        return INVALID_RESULT;
    }
    let input = x as f32;
    (1.0f32 / (1.0f32 + std::f32::consts::E.powf(-input))) as f64
}
