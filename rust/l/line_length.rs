const INVALID_RESULT: f64 = -1.0e300;

/// Repeated-step polyline length for the source demo curve sin(10*x).
#[no_mangle]
pub extern "C" fn line_length(x_start: f64, x_end: f64, steps_value: f64) -> f64 {
    if x_start.is_nan() || x_end.is_nan() || steps_value.is_nan()
        || !(-10.0..=10.0).contains(&x_start) || !(-10.0..=10.0).contains(&x_end)
        || x_start > x_end || steps_value < 1.0 || steps_value > 10000.0
        || steps_value.fract() != 0.0 {
        return INVALID_RESULT;
    }
    let steps = steps_value as usize;
    let mut x1 = x_start;
    let mut fx1 = (10.0 * x_start).sin();
    let mut length = 0.0;
    for _ in 0..steps {
        let x2 = (x_end - x_start) / steps as f64 + x1;
        let fx2 = (10.0 * x2).sin();
        let dx = x2 - x1;
        let dy = fx2 - fx1;
        length += (dx * dx + dy * dy).sqrt();
        x1 = x2;
        fx1 = fx2;
    }
    length
}
