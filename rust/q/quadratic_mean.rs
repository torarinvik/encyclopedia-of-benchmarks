const MAX_LENGTH: usize = 64;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn quadratic_mean(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length == 0 || length > MAX_LENGTH { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let mut square_sum = 0.0;
    for &value in values {
        if !(-1000..=1000).contains(&value) { return INVALID_RESULT; }
        let converted = value as f64;
        square_sum += converted * converted;
    }
    (square_sum / length as f64).sqrt()
}
