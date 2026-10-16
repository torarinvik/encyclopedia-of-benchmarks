const INVALID_RESULT: f64 = -1.0e300;

fn integrand(function_id: i64, x: f64) -> f64 {
    match function_id {
        0 => x.sqrt() + x.ln(),
        1 => (-x).exp() * (4.0 - x.powf(2.0)),
        2 => (2.0 * x.powf(3.0) + 3.0).sqrt(),
        3 => x + (2.0 * x + 1.0).ln(),
        _ => INVALID_RESULT,
    }
}

#[no_mangle]
pub unsafe extern "C" fn midpoint_integral_method(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 4 { return INVALID_RESULT; }
    let input = std::slice::from_raw_parts(values, length);
    let function_id = input[0];
    let intervals = input[1];
    let a_milli = input[2];
    let b_milli = input[3];
    if !(0..=3).contains(&function_id) || !(2..=64).contains(&intervals) || intervals % 2 != 0 ||
        a_milli < 0 || a_milli >= b_milli || b_milli > 10000 { return INVALID_RESULT; }
    let a = a_milli as f64 / 1000.0;
    let b = b_milli as f64 / 1000.0;
    let h = (b - a) / intervals as f64;
    let mut xi = a;
    let mut total = 0.0;
    for _ in 0..intervals {
        total += integrand(function_id, xi + h / 2.0);
        xi += h;
    }
    total * h
}
