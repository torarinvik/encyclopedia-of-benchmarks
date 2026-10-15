const MAX_LENGTH: usize = 256;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn mean_absolute_error_loss(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 3 || length > 2 * MAX_LENGTH + 1 { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let count_value = values[0];
    if count_value < 1 || count_value > MAX_LENGTH as i64 || length != 2 * count_value as usize + 1 {
        return INVALID_RESULT;
    }
    let count = count_value as usize;
    let mut absolute_sum = 0.0;
    for index in 0..count {
        let predicted = values[index + 1];
        let actual = values[index + 1 + count];
        if !(-1_000_000..=1_000_000).contains(&predicted) || !(-1_000_000..=1_000_000).contains(&actual) {
            return INVALID_RESULT;
        }
        absolute_sum += (predicted - actual).abs() as f64;
    }
    absolute_sum / count as f64
}
