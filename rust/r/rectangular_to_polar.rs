const INVALID_RESULT: f64 = -1.0e300;

fn round_to_two_decimals(value: f64) -> f64 {
    (value * 100.0).round() / 100.0
}

#[no_mangle]
pub extern "C" fn rectangular_to_polar(real: f64, imag: f64, component: f64) -> f64 {
    if !real.is_finite() || !imag.is_finite() || !component.is_finite()
        || !(-1_000_000.0..=1_000_000.0).contains(&real)
        || !(-1_000_000.0..=1_000_000.0).contains(&imag)
        || (component != 0.0 && component != 1.0) { return INVALID_RESULT; }
    if component == 0.0 {
        round_to_two_decimals((real * real + imag * imag).sqrt())
    } else {
        round_to_two_decimals(imag.atan2(real).to_degrees())
    }
}
