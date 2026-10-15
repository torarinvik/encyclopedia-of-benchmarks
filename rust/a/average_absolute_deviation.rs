const MAX_LENGTH: usize = 256;
const MIN_VALUE: i64 = -2_147_483_648;
const MAX_VALUE: i64 = 2_147_483_647;
const INVALID_RESULT: f64 = -1.0e300;
#[no_mangle]
pub unsafe extern "C" fn average_absolute_deviation(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length == 0 || length > MAX_LENGTH { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(values, length);
    let mut sum = 0.0f64;
    for &value in values {
        if !(MIN_VALUE..=MAX_VALUE).contains(&value) { return INVALID_RESULT; }
        sum += value as f64;
    }
    let average = sum / length as f64;
    let mut deviations = 0.0f64;
    for &value in values {
        let value = value as f64;
        deviations += if value >= average { value - average } else { average - value };
    }
    deviations / length as f64
}
