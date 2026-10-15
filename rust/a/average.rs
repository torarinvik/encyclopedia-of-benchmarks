const MAX_INPUT_LENGTH: usize = 4096;
const MAX_ABS_VALUE: i64 = 1_000_000_000;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn average(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length == 0 || length > MAX_INPUT_LENGTH {
        return INVALID_RESULT;
    }
    let values = std::slice::from_raw_parts(values, length);
    let mut sum = 0i64;
    for &value in values {
        if !(-MAX_ABS_VALUE..=MAX_ABS_VALUE).contains(&value) {
            return INVALID_RESULT;
        }
        sum += value;
    }
    sum as f64 / length as f64
}
