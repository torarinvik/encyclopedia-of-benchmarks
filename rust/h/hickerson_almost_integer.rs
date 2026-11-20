const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn hickerson_almost_integer(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 1 { return INVALID_RESULT; }
    let input = std::slice::from_raw_parts(values, length);
    let n = input[0];
    if !(1..=17).contains(&n) { return INVALID_RESULT; }
    let log_two = 2.0_f64.ln();
    let mut value = 1.0 / (2.0 * log_two * log_two);
    for index in 2..=n {
        value = (index as f64 / log_two) * value;
    }
    value
}
