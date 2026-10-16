const MAX_LENGTH: usize = 1024;
const INVALID_RESULT: i64 = i64::MIN;

#[no_mangle]
pub extern "C" fn calculate_median(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(1..=MAX_LENGTH).contains(&length) {
        return INVALID_RESULT;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let middle = length / 2;
    if length % 2 != 0 { return values[middle] * 2; }
    values[middle - 1] + values[middle]
}
