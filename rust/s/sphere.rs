const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn sphere(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length != 2 { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let (mode, radius) = (values[0], values[1]);
    if (mode != 0 && mode != 1) || !(0..=1_000_000).contains(&radius) { return INVALID_RESULT; }
    let r = radius as f64;
    let r2 = r * r;
    if mode == 0 { return (((r2 * r) * std::f64::consts::PI) * 4.0) / 3.0; }
    (r2 * std::f64::consts::PI) * 4.0
}
