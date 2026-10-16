/// Count every pair of distinct indices whose values sum to the target.
#[no_mangle]
pub extern "C" fn pairs_with_given_sum(input: *const i64, length: usize) -> i64 {
    const MAX_INPUT_LENGTH: usize = 257;
    if input.is_null() || length == 0 || length > MAX_INPUT_LENGTH {
        return -2;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values.iter().any(|value| *value < i32::MIN as i64 || *value > i32::MAX as i64) {
        return -2;
    }
    let target = values[0];
    let value_count = length - 1;
    let mut pairs = 0_i64;
    for left in 0..value_count {
        for right in left + 1..value_count {
            if values[left + 1] + values[right + 1] == target {
                pairs += 1;
            }
        }
    }
    pairs
}
