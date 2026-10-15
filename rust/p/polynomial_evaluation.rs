/// Bounded integer port of the pinned floating-point Horner routine.
const INVALID_RESULT: i64 = i64::MIN;

#[no_mangle]
pub extern "C" fn polynomial_evaluation(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > 10 { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let count = values[0];
    let x = values[1];
    if !(0..=8).contains(&count) || length != (count as usize) + 2 { return INVALID_RESULT; }
    if !(-10..=10).contains(&x) { return INVALID_RESULT; }
    if values[2..].iter().any(|&coefficient| !(-1000..=1000).contains(&coefficient)) {
        return INVALID_RESULT;
    }
    let mut result = 0_i64;
    for index in (0..count as usize).rev() {
        result = result * x + values[index + 2];
    }
    result
}
