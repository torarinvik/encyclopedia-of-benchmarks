/// Pinned Rust tanh-based GELU approximation.
const INVALID_RESULT: f64 = -1.0e300;
const E_VALUE: f64 = std::f64::consts::E;
const PI_VALUE: f64 = std::f64::consts::PI;

fn source_tanh(value: f64) -> f64 {
    (2.0 / (1.0 + E_VALUE.powf(-2.0 * value))) - 1.0
}

#[no_mangle]
pub extern "C" fn gaussian_error_linear_unit_tanh(x: f64) -> f64 {
    if !x.is_finite() || x < -100.0 || x > 100.0 { return INVALID_RESULT; }
    let scale = (2.0 / PI_VALUE).powf(0.5);
    let z = scale * (x + 0.044715 * x.powf(3.0));
    x * 0.5 * (1.0 + source_tanh(z))
}
