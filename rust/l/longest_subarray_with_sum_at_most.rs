const INVALID_RESULT: i64 = -1;
const MAX_INPUT_LENGTH: usize = 259;
const MAX_DOMAIN_VALUE: i64 = i32::MAX as i64;
#[no_mangle]
pub unsafe extern "C" fn longest_subarray_with_sum_at_most(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=MAX_INPUT_LENGTH).contains(&length) { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let (target, raw_count) = (values[0], values[1]);
    if target < 0 || target > MAX_DOMAIN_VALUE || raw_count < 0 || raw_count > 256 { return INVALID_RESULT; }
    let count = raw_count as usize;
    if length != count + 2 { return INVALID_RESULT; }
    for &value in &values[2..] {
        if value < 0 || value > MAX_DOMAIN_VALUE { return INVALID_RESULT; }
    }
    let (mut left, mut best_length) = (0, 0);
    let mut window_sum = 0_i64;
    for right in 0..count {
        window_sum += values[right + 2];
        while window_sum > target && left <= right {
            window_sum -= values[left + 2];
            left += 1;
        }
        let current_length = if left <= right { right - left + 1 } else { 0 };
        best_length = best_length.max(current_length);
    }
    best_length as i64
}
