/// Bounded selector wrapper for the Java thin-lens operations.
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn thin_lens(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let (operation, a, b) = (input[0], input[1], input[2]);
    if !(-1000..=1000).contains(&a) || !(-1000..=1000).contains(&b) { return INVALID_RESULT; }
    match operation {
        0 => {
            if a == 0 || b == 0 || a == b { return INVALID_RESULT; }
            let f = a as f64;
            let u = b as f64;
            1.0 / ((1.0 / f) - (1.0 / u))
        }
        1 => {
            if b == 0 { return INVALID_RESULT; }
            a as f64 / b as f64
        }
        2 => {
            if b != 0 { return INVALID_RESULT; }
            if a > 0 { 1.0 } else { 0.0 }
        }
        _ => INVALID_RESULT,
    }
}
