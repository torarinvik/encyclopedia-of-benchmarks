const MAX_LENGTH: usize = 256;

fn find_max_range(values: &[i64], low: usize, high: usize) -> i64 {
    if low == high { return values[low]; }
    let middle = low + (high - low) / 2;
    let left = find_max_range(values, low, middle);
    let right = find_max_range(values, middle + 1, high);
    left.max(right)
}

#[no_mangle]
pub unsafe extern "C" fn find_max_recursion(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length == 0 || length > MAX_LENGTH { return -1; }
    let slice = std::slice::from_raw_parts(values, length);
    if slice.iter().any(|value| *value < i32::MIN as i64 || *value > i32::MAX as i64) { return -1; }
    find_max_range(slice, 0, length - 1)
}
