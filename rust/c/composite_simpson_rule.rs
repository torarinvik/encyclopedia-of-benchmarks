/// Composite Simpson quadrature for the source's four sample functions on [1, 3].
const INVALID_RESULT: f64 = -1.0;
const MAX_INTERVALS: i32 = 128;

fn sample(function_id: i32, x: f64) -> f64 {
    match function_id {
        0 => x.sqrt() + x.ln(),
        1 => (-x).exp() * (4.0 - x.powf(2.0)),
        2 => (2.0 * x.powf(3.0) + 3.0).sqrt(),
        _ => x + (2.0 * x + 1.0).ln(),
    }
}

#[no_mangle]
pub extern "C" fn composite_simpson_rule(intervals_input: f64, function_id_input: f64) -> f64 {
    if !intervals_input.is_finite() || !function_id_input.is_finite()
        || intervals_input < 2.0 || intervals_input > MAX_INTERVALS as f64
        || function_id_input < 0.0 || function_id_input > 3.0
        || intervals_input.fract() != 0.0 || function_id_input.fract() != 0.0 {
        return INVALID_RESULT;
    }
    let intervals = intervals_input as i32;
    if intervals % 2 != 0 { return INVALID_RESULT; }
    let function_id = function_id_input as i32;
    let h = 2.0 / intervals as f64;
    let mut x = 1.0;
    let mut sum = 0.0;
    for i in 0..=intervals {
        let y = sample(function_id, x);
        let weight = if i == 0 || i == intervals { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        sum += weight * y;
        x += h;
    }
    sum * (h / 3.0)
}
