const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn circular_arc(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length != 3 { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let (mode, radius, degrees) = (values[0], values[1], values[2]);
    if (mode != 0 && mode != 1) || !(-1_000_000..=1_000_000).contains(&radius) || !(-360_000..=360_000).contains(&degrees) { return INVALID_RESULT; }
    let angle = degrees as f64 * (std::f64::consts::PI / 180.0);
    if mode == 0 { return radius as f64 * angle; }
    (radius * radius) as f64 * angle / 2.0
}
