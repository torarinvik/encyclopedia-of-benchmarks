const MAX_ITEMS: usize = 256;
const MAX_SAFE_INTEGER: i64 = 9_007_199_254_740_991;
const INVALID_RESULT: i64 = i64::MIN;

fn gcd_nonnegative(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

#[no_mangle]
pub extern "C" fn greatest_common_factor(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_ITEMS + 1 { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let count = values[0];
    if count < 1 || count > MAX_ITEMS as i64 || length != count as usize + 1 { return INVALID_RESULT; }
    let mut result = values[1];
    if !(0..=MAX_SAFE_INTEGER).contains(&result) { return INVALID_RESULT; }
    for &value in &values[2..] {
        if !(0..=MAX_SAFE_INTEGER).contains(&value) { return INVALID_RESULT; }
        result = gcd_nonnegative(result, value);
    }
    result
}
