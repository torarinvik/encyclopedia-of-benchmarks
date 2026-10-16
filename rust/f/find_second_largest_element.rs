const INVALID_RESULT: i64 = i64::MIN;
const INT32_MIN_VALUE: i64 = i32::MIN as i64;
const INT32_MAX_VALUE: i64 = i32::MAX as i64;

#[no_mangle]
pub extern "C" fn find_second_largest_element(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(3..=10001).contains(&length) { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let n = input[0];
    if !(2..=10000).contains(&n) || length != n as usize + 1 { return INVALID_RESULT; }
    let values = &input[1..];
    if values.iter().any(|&value| value < INT32_MIN_VALUE || value > INT32_MAX_VALUE) { return INVALID_RESULT; }
    let largest = *values.iter().max().unwrap();
    let mut second = INT32_MIN_VALUE - 1;
    for &value in values {
        if value < largest && value > second { second = value; }
    }
    if second == INT32_MIN_VALUE - 1 { INVALID_RESULT } else { second }
}
