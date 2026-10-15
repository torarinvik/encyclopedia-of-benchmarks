const MAX_ITEMS: i64 = 100_000;
const MAX_SAFE_INTEGER: i64 = 9_007_199_254_740_991;

/// Two-ended linear search with source-compatible endpoint priority.
#[no_mangle]
pub unsafe extern "C" fn double_linear_search(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > 100_002 {
        return -1;
    }
    let values = std::slice::from_raw_parts(values, length);
    let target = values[0];
    let count_value = values[1];
    if !(-MAX_SAFE_INTEGER..=MAX_SAFE_INTEGER).contains(&target)
        || !(0..=MAX_ITEMS).contains(&count_value)
        || length != count_value as usize + 2
    {
        return -1;
    }
    let count = count_value as usize;
    if values[2..].iter().any(|&value| !(-MAX_SAFE_INTEGER..=MAX_SAFE_INTEGER).contains(&value)) {
        return -1;
    }
    let (mut start, mut right) = (0usize, count);
    while start < right {
        if values[start + 2] == target {
            return start as i64;
        }
        if values[right + 1] == target {
            return (right - 1) as i64;
        }
        start += 1;
        right -= 1;
    }
    -1
}
