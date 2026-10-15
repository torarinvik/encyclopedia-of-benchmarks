const MAX_VALUES: usize = 256;
const INVALID_RESULT: i64 = i64::MIN;

#[no_mangle]
pub extern "C" fn min_values(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 || length > MAX_VALUES + 1 { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let count = values[0];
    if count < 1 || count > MAX_VALUES as i64 || length != count as usize + 1 { return INVALID_RESULT; }
    let mut result = values[1];
    if result < i32::MIN as i64 || result > i32::MAX as i64 { return INVALID_RESULT; }
    for &value in &values[2..] {
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return INVALID_RESULT; }
        if value < result { result = value; }
    }
    result
}
