const MAX_LENGTH: usize = 64;
const MAX_ABS_VALUE: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn variance(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 2 || length > MAX_LENGTH {
        return INVALID_RESULT;
    }
    let values = std::slice::from_raw_parts(values, length);
    let mut sum = 0.0f64;
    for &value in values {
        if !(-MAX_ABS_VALUE..=MAX_ABS_VALUE).contains(&value) {
            return INVALID_RESULT;
        }
        sum += value as f64;
    }
    let average = sum / length as f64;
    let mut squared_deviations = 0.0f64;
    for &value in values {
        let difference = value as f64 - average;
        squared_deviations += difference * difference;
    }
    squared_deviations / (length - 1) as f64
}
