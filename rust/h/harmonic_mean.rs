const MAX_LENGTH: usize = 64;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn harmonic_mean(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length == 0 || length > MAX_LENGTH { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values.iter().any(|&value| !(1..=1000).contains(&value)) { return INVALID_RESULT; }
    let reciprocal_sum: f64 = values.iter().map(|&value| 1.0 / value as f64).sum();
    length as f64 / reciprocal_sum
}
